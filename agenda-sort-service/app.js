import mu from 'mu';
import { ok } from 'assert';

const app = mu.app;
const bodyParser = require('body-parser');
const repository = require('./repository');
const cors = require('cors');

app.use(bodyParser.json({ type: 'application/*+json' }));
app.use(cors());


app.post('/', (req, res) => {
    return handleSortRequest(req, res);
});

app.get('/', (req, res) => {
    return handleSortRequest(req, res, true);
});

const handleSortRequest = async (req, res, queryOnly) => {
    let agendaId = req.query.agendaId;

    try {
        const agendaItems = await repository.getAgendaPriorities(agendaId);
        const previousPrio = await repository.getLastPriorityOfAgendaitemInAgenda(agendaId);
        const prioritizedAgendaItems = await sortAgendaItemsByMandates(agendaItems, (previousPrio[0].maxPrio || 0));

        if (!queryOnly) {
            await repository.updateAgendaItemPriority(prioritizedAgendaItems);
        }

        res.send({ status: ok, statusCode: 200, body: { items: prioritizedAgendaItems } });

    } catch (error) {
        console.error(error);
        res.send({ status: ok, statusCode: 500, body: { error } });
    }
};

const sortAgendaItemsByMandates = async (agendaItems, previousPrio) => {
    agendaItems.sort((a, b) => {
        let priorityDiff = a.mandatePriority - b.mandatePriority;
        if (priorityDiff == 0) {
            return a.mandateeCount - b.mandateeCount;
        } else {
            return priorityDiff;
        }
    });
    for (let i = 0; i < agendaItems.length; i++) {
        agendaItems[i].priority = i + 1 + parseInt(previousPrio);
    }

    return agendaItems;
};

app.get('/sortedAgenda', async (req, res) => {
    const sessionId = req.query.sessionId;
    const currentAgendaID = req.query.selectedAgenda;
    const agendaitemsOfSelectedAgenda = await repository.getAllAgendaItemsFromAgenda(currentAgendaID);

    const agendaitems = await repository.getAllAgendaitemsOfTheSessionWithAgendaName(sessionId);

    let sortedAgendaitems = agendaitems.sort((a, b) => {
        if (a.agendaName === "Ontwerpagenda") {
            return 1;
        }
        if (b.agendaName === "Ontwerpagenda") {
            return 1;
        }

        if (a.agendaName < b.agendaName)
            return -1;
        if (a.agendaName > b.agendaName)
            return 1;
        return 0;
    })

    const changedAgendaItems = await setAllMappedPropertiesAndReturnSortedAgendaitems(sortedAgendaitems, agendaitemsOfSelectedAgenda, currentAgendaID);

    const combinedAgendas = reduceAgendaitemsToUniqueAgendas(changedAgendaItems);
    const combinedAgendasWithAgendaitems = getGroupedAgendaitems(combinedAgendas);

    await setFoundPrioritiesToAllAgendaItemsOveral(combinedAgendasWithAgendaitems);

    res.send(combinedAgendasWithAgendaitems);
})

const reduceAgendaitemsPerTitle = (agendaitems) => {
    return agendaitems.reduce((agendaItems, agendaitem) => {
        agendaItems[agendaitem.groupTitle] = agendaItems[agendaitem.groupTitle] || { agendaitems: [], foundPriority: 2147111111, mandatees: agendaitem.mandatees }
        agendaItems[agendaitem.groupTitle].agendaitems.push(agendaitem);
        agendaItems[agendaitem.groupTitle].foundPriority = Math.min(agendaItems[agendaitem.groupTitle].foundPriority, agendaitem.priority);

        return agendaItems;
    }, {});
}

const reduceMandateesToUniqueSubcases = (agendaitems) => {
    return agendaitems.reduce((agendaItems, agendaitem) => {
        agendaItems[agendaitem.subcaseId] = agendaItems[agendaitem.subcaseId] || { mandatees: [] }

        agendaItems[agendaitem.subcaseId].mandatees.push(
            { title: agendaitem.title, priority: agendaitem.priority }
        );
        return agendaItems;
    }, {});
}

const reduceAgendaitemsToUniqueAgendas = (agendaitems) => {
    const subcaseIdsParsed = [];
    return agendaitems.reduce((agendaItems, agendaitem) => {

        agendaItems[agendaitem.agendaName] = agendaItems[agendaitem.agendaName] || { items: [], agendaId: agendaitem.agendaId }
        if (!subcaseIdsParsed.includes(agendaitem.subcase)) {
            delete agendaitem.mandatee;
            subcaseIdsParsed.push(agendaitem.subcase);
            agendaItems[agendaitem.agendaName].items.push(agendaitem);
        }

        return agendaItems;
    }, {});
}

const setAllMappedPropertiesAndReturnSortedAgendaitems = (agendaitems, agendaitemsOfSelectedAgenda, currentAgendaID) => {
    const mandatees = reduceMandateesToUniqueSubcases(agendaitems);
    return agendaitems.map((agendaitem) => {
        const uniqueMandatees = getUniqueMandatees(mandatees[agendaitem.subcaseId].mandatees);
        agendaitem['mandatees'] = uniqueMandatees;
        const titles = uniqueMandatees.map((item) => item.title);
        agendaitem['groupTitle'] = titles.join(', ');
        const priorities = uniqueMandatees.map((item) => parseInt(item.priority));
        let minPriority = Math.min(...priorities);
        // create a priority based on the multiple priorities in the mandatee list
        if (priorities.length > 1) {
            priorities.map((priority) => {
                minPriority += (priority / 1000);
            })
            agendaitem['priority'] = minPriority;
        } else {
            agendaitem['priority'] = minPriority;
        }
        const foundAgendaItem = agendaitemsOfSelectedAgenda.find((agendaitemToCheck) => agendaitemToCheck.subcaseId === agendaitem.subcaseId);
        agendaitem['selectedAgendaId'] = currentAgendaID;

        if (foundAgendaItem) {
            agendaitem['id'] = foundAgendaItem.id;
        }

        return agendaitem;
    });
}

const getGroupedAgendaitems = (combinedAgendas) => {
    return Object.entries(combinedAgendas).map((itemArray) => {
        if (itemArray[1].items.length > 0) {
            let obj = {
                agendaName: itemArray[0],
                agendaId: itemArray[1].agendaId,
                groups: Object.entries(reduceAgendaitemsPerTitle(itemArray[1].items)).map((entry) => {
                    return {
                        title: entry[0],
                        priority: entry[1].foundPriority,
                        mandatees: entry[1].mandatees,
                        agendaitems: entry[1].agendaitems.sort((a, b) => parseInt(a.agendaitemPrio) > parseInt(b.agendaitemPrio))
                    }
                }).sort((a, b) => a.priority - b.priority)
            }

            return obj;
        }
    }).filter((item) => item).sort((a, b) => {
        if (a.agendaName < b.agendaName)
            return -1;
        if (a.agendaName > b.agendaName)
            return 1;
        return 0;
    });
}

const getUniqueMandatees = (mandatees) => {
    let uniqueMandatees = []
    mandatees.map(mandatee => {
        const foundMandatee = uniqueMandatees.find((mandateeToCheck) => mandatee.title === mandateeToCheck.title);
        if (!foundMandatee) {
            uniqueMandatees.push(mandatee)
        }
    });
    return uniqueMandatees.sort((a, b) => parseInt(a.priority) - parseInt(b.priority));
}

async function setFoundPrioritiesToAllAgendaItemsOveral(combinedAgendasWithAgendaitems) {
    return await Promise.all(combinedAgendasWithAgendaitems.map(async (combinedAgenda) => {
        const agendaId = combinedAgenda.agendaId;
        const itemsToPrioritise = await repository.getAgendaPrioritiesWithoutFilter(agendaId);
        const prioritizedAgendaItems = await sortAgendaItemsByMandates(itemsToPrioritise, 0);
        combinedAgenda.groups.map((group) => {
            group.agendaitems.map((agendaitem) => {
                console.log(prioritizedAgendaItems)
                const foundItem = prioritizedAgendaItems.find((prioritizedAgendaItem) => prioritizedAgendaItem.subcaseId === agendaitem.subcaseId);
                console.log(foundItem)
                if (foundItem) {
                    agendaitem.foundPrio = foundItem.priority;
                }
            });
            group.agendaitems = group.agendaitems.sort((a, b) => a.foundPrio - b.foundPrio);
        });
    }));
}
