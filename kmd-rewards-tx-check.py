from lib import transaction, bitcoin, util
from lib.util import bfh, bh2u
from lib.transaction import Transaction
from lib.komodo_interest import calcInterest

import urllib.request, urllib.parse, urllib.error
import urllib.request, urllib.error, urllib.parse
import json

explorerUrl = 'https://kmd.explorer.dexstats.info/insight-api-komodo/';
rawtx = 'raw tx hex here'

jsontx = transaction.deserialize(rawtx)
inputs = jsontx.get('inputs')
outputs = jsontx.get('outputs')
locktime = jsontx.get('lockTime', 0)

sumVin = 0
sumVout = 0
totalRewards = 0

for txin in inputs:
  print('get vin data', txin['prevout_hash'])
  url = explorerUrl + 'rawtx/' + txin['prevout_hash']
  response = urllib.request.urlopen(url)
  data = json.loads(response.read())

  if data is not None and 'rawtx' in data:
    # print('INSIGHT explorer response', data)
    vinTx = transaction.deserialize(data['rawtx'])
    vinOutputs = vinTx.get('outputs')
    vinLocktime = vinTx.get('lockTime', 0)
    vinVal = vinOutputs[txin['prevout_n']]['value']
    sumVin += vinVal
    rewards = calcInterest(vinLocktime, vinVal, 7777776)
    totalRewards += rewards 
    print('rewards', rewards)
  else:
    print('unable to get', txin['prevout_hash'])

for txout in outputs:
  sumVout += txout['value']

print('fee', abs(sumVin - sumVout))

if (abs(sumVin - sumVout) > totalRewards):
  print('trying to claim too much')
  print(str(abs(sumVin - sumVout) - totalRewards) + ' (' + str((abs(sumVin - sumVout) - totalRewards) * 0.00000001) + ')', 'over the limit')