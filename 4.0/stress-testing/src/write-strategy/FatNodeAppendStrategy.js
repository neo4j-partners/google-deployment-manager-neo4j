const Strategy = require('../Strategy');
const Promise = require('bluebird');
const uuid = require('uuid');

class FatNodeAppendStrategy extends Strategy {
    constructor(props) {
        super(props);
        this.name = 'FatNodeAppend';
        this.label = props.label;
    }

    run(driver) {
        if (!this.session) {
            this.session = driver.session();
        }

        const p = this.randInt(10000000);
        const r = p - 10000;

        const data = [];
        for (let i = 0; i < 1000; i++) {
            data.push(uuid.v4());
        }

        this.lastQuery = `FOREACH (id IN range(0,10) | CREATE (f:FatNode {
            timestamp: timestamp(),
            data: $data,
            uuid: $uuid
        }))`;
        this.lastParams = { uuid: uuid.v4(), data };
        
        const f = (s = driver.session()) => s.writeTransaction(tx => tx.run(this.lastQuery, this.lastParams));
        return this.time(f);
    }
}

module.exports = FatNodeAppendStrategy;