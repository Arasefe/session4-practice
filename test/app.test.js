import {test, before, after} from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from '../src/app.js';

let server;
let base;

before(async () => {
	server = createServer();
	await new Promise(resolve => server.listen(0, resolve));
	base = `http://localhost:${server.address().port}`;
});

after(() => server.close());

test('/health answers ok', async () => {
	const res = await fetch(`${base}/health`);
	assert.equal(res.status, 200);
	assert.deepEqual(await res.json(), {status: 'ok'});
});

test('/invoices/:id returns the invoice with its total', async () => {
	const body = await (await fetch(`${base}/invoices/5512`)).json();
	assert.equal(body.total, 100.01);
});

test('unknown invoice is a 404', async () => {
	const res = await fetch(`${base}/invoices/1`);
	assert.equal(res.status, 404);
});
