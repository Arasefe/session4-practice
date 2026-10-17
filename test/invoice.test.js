import {test} from 'node:test';
import assert from 'node:assert/strict';
import {invoiceTotal, renderInvoice} from '../src/invoice.js';

test('invoice total sums line items', () => {
	assert.equal(invoiceTotal([{quantity: 2, unitPrice: 49.99}]), 99.98);
});

test('invoice total rounds to cents', () => {
	assert.equal(invoiceTotal([{quantity: 3, unitPrice: 33.335}, {quantity: 1, unitPrice: 0.005}]), 100.01);
});

test('empty invoice totals zero', () => {
	assert.equal(invoiceTotal([]), 0);
});

test('rendered invoice carries a footer', () => {
	const invoice = renderInvoice({id: 1, customer: 'Test', items: []});
	assert.match(invoice.footer, /Thank you for your business/);
});
