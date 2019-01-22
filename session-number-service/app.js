import mu from 'mu';
import { ok } from 'assert';

const app = mu.app;
const bodyParser = require('body-parser');

app.use(bodyParser.json({ type: 'application/*+json' }))

app.get('/assignNewSessionNumbers', async function (req, res) {
  let countSessions = await getSessionCount();

  let sessions = await getAllSessions();
  let beginNumber = parseInt(countSessions) - sessions.length;

  sessions = sessions.sort((a, b) => {
    return new Date(a.plannedstart) - new Date(b.plannedstart);
  });

  for (let i = 0; i < sessions.length; i++) {
    if (!sessions[i]) {
      continue;
    }
    sessions[i].previousNumber = sessions[i].number;
    sessions[i].number = i + beginNumber + 1;
  }

  let updatedDate = await updateSessionNumbers(sessions);
  res.send({ status: ok, statusCode: 200, body: { sessions: sessions, updateMessage: updatedDate } });
})

async function getSessionCount() {
  const query = `
  PREFIX vo-besluit: <https://data.vlaanderen.be/ns/besluitvorming#>
  PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
  PREFIX vo-gen: <https://data.vlaanderen.be/ns/generiek#> 

  select(count(distinct ?session) as ?nSessions) where {
  ?session a vo-besluit:Zitting ;
  mu:uuid ?uuid ;
  vo-besluit:number ?number ;
  vo-gen:geplandeStart ?plannedstart .
  }`

  let data = await mu.query(query);

  return data.results.bindings[0].nSessions.value;
}

async function getAllSessions() {
  let dateOfYesterday = (d => new Date(d.setDate(d.getDate() - 1)))(new Date);
  dateOfYesterday.setHours(23, 59, 59, 0);

  const query = `
  PREFIX vo-besluit: <https://data.vlaanderen.be/ns/besluitvorming#>
  PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
  PREFIX vo-gen: <https://data.vlaanderen.be/ns/generiek#> 
  
  SELECT ?session ?plannedstart ?number WHERE {
    GRAPH <http://mu.semte.ch/application> 
    {
    ?session a vo-besluit:Zitting ;
    mu:uuid ?uuid ;
    vo-gen:geplandeStart ?plannedstart ;
    vo-besluit:number ?number .
    FILTER(str(?plannedstart) > "${dateOfYesterday.toISOString()}")
  }
}`

  let data = await mu.query(query);
  const vars = data.head.vars;

  return data.results.bindings.map(binding => {
    let obj = {};
    vars.forEach(varKey => {
      obj[varKey] = binding[varKey].value;
    });
    return obj;
  })
}

async function updateSessionNumbers(sessions) {
  let deleteString = "";
  let insertString = "";
  sessions.forEach(obj => {
    deleteString = `${deleteString}
     <${obj.session}> vo-besluit:number """${obj.previousNumber}"""^^xsd:decimal .
    `
    insertString = `${insertString}
    <${obj.session}> vo-besluit:number """${obj.number}"""^^xsd:decimal .
    `
  })

  const query = `
  PREFIX vo-besluit: <https://data.vlaanderen.be/ns/besluitvorming#>
  PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
  prefix vo-gen: <https://data.vlaanderen.be/ns/generiek#> 
  
  DELETE DATA { 
    GRAPH <http://mu.semte.ch/application> { 
      ${deleteString}
    } 
  }

  INSERT DATA { 
    GRAPH <http://mu.semte.ch/application> { 
      ${insertString}
    } 
  }
  `

  return mu.update(query);
}

mu.app.use(mu.errorHandler);