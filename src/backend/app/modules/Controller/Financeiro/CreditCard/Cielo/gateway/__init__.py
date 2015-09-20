# -*- coding: utf-8 -*-
from decimal import Decimal
from cielo import PaymentAttempt, GetAuthorizedException


class Gateway:

    credentials_sandbox = {
        'affiliation_id': 'XXXX',
        'api_key': 'XXXX',
    }

    credentials_eveo = {
        'affiliation_id': 'XXXX',
        'api_key': 'XXXX',
    }

    def __init__(self, card_type, total, order_id, card_number, exp_date, transaction_type, card_holders_name, installments, cvv=None, sandbox=True):

        # formatting data
        card_type = card_type.lower()

        total = str(total)
        total = Decimal('%s.%s' % (total[:-2], total[-2:]))

        exp_date = str(exp_date)

        if len(exp_date) == 3:
            exp_date = '0%s' % exp_date

        exp_month = exp_date[:2]
        exp_year = exp_date[2:]

        if transaction_type == 'S':
            transaction = PaymentAttempt.CASH
        elif transaction_type == 'L':
            transaction = PaymentAttempt.INSTALLMENT_STORE
        elif transaction_type == 'O':
            transaction = PaymentAttempt.INSTALLMENT_CIELO

        installments = int(installments)

        if installments == 1:
            transaction = PaymentAttempt.CASH

        cvv_indicator = 0 if not cvv else 1

        self.params = dict(self.credentials_sandbox if sandbox else self.credentials_eveo, **{
            'card_type': card_type,
            'total': total,
            'order_id': order_id,
            'card_number': card_number,
            'cvc2': cvv or '',
            'cvc2_indicator': cvv_indicator,
            'exp_month': exp_month,
            'exp_year': exp_year,
            'transaction': transaction,
            'card_holders_name': card_holders_name,
            'installments': installments,
            'soft_descriptor': 'Fatura %s' % order_id,
            'sandbox': sandbox,
        })

    def process(self):

        attempt = PaymentAttempt(**self.params)

        result = {
            'success': False,
        }

        try:
            attempt.get_authorized()
        except GetAuthorizedException, e:
            result['msg'] = u'Não foi possível processar: %s' % e

        else:
            result = attempt.capture()

        return result


def pay(card_type, total, order_id, card_number, exp_date, transaction_type, card_holders_name, installments, cvv=None, sandbox=True):

    try:

        gateway = Gateway(card_type, total, order_id, card_number, exp_date, transaction_type, card_holders_name, installments, cvv, bool(sandbox))

        return gateway.process()

    except Exception as e:
        print e
        raise