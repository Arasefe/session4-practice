import http from 'node:http';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {PORT} from './config.js';
import {renderInvoice} from './invoice.js';

const invoices = {
	5512: {id: 5512, customer: 'Northwind', items: [{quantity: 3, unitPrice: 33.335}, {quantity: 1, unitPrice: 0.005}]},
	5513: {id: 5513, customer: 'Contoso', items: [{quantity: 2, unitPrice: 49.99}]},
};

// The release workflow stamps the commit into dist/version.txt.
function version() {
	try {
		return readFileSync(new URL('version.txt', import.meta.url), 'utf8').trim();
	} catch {
		return 'dev';
	}
}

function send(res, status, body) {
	res.writeHead(status, {'content-type': 'application/json'});
	res.end(JSON.stringify(body));
}

export function createServer() {
	return http.createServer((req, res) => {
		const url = new URL(req.url, 'http://localhost');
		if (url.pathname === '/health') return send(res, 200, {status: 'ok'});
		if (url.pathname === '/version') return send(res, 200, {version: version()});

		const match = url.pathname.match(/^\/invoices\/(\d+)$/);
		if (match && invoices[match[1]]) return send(res, 200, renderInvoice(invoices[match[1]]));

		send(res, 404, {error: 'not found'});
	});
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	createServer().listen(PORT, () => console.log(`invoice-svc listening on :${PORT}`));
}
