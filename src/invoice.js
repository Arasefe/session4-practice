import {roundTo} from 'round-to';

export const COMPANY = 'Acme Corp';

// Sum line items and round to cents once, at the end.
export function invoiceTotal(items) {
	const total = items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
	return roundTo(total, 2);
}

export function renderInvoice(invoice) {
	return {
		id: invoice.id,
		customer: invoice.customer,
		items: invoice.items,
		total: invoiceTotal(invoice.items),
		footer: `Thank you for your business. ${COMPANY}`,
	};
}
