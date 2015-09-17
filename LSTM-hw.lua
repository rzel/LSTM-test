-- Practical 5
-- University of OXFORD

-- Implement LSTM from Graves' paper
-- i_t = \sigma(linear(x_t, h_{t-1}))
-- f_t = \sigma(linear(x_t, h_{t-1}))
-- c_t = f_t * c_{t-1} + i_t * tanh(linear(x_t, h_{t-1})
-- o_t = \sigma(linear(x_t, h_{t-1}))
-- h_t = o_t * tanh(c_t)

torch.manualSeed(0)
require 'nngraph'
local c = require 'trepl.colorize'

-- Node values (and size)
n_x = 5; T = 10
xv = {}
for t = 1, T do
   xv[t] = torch.randn(n_x)
end

-- Graphical model definition
nngraph.setDebug(true)
local x_t  = nn.Identity()()
x_t:annotate{graphAttributes = {color = 'red', fontcolor = 'red'}}
local h_tt = nn.Identity()() -- h_tt := h_{t-1}
h_tt:annotate{graphAttributes = {color = 'red', fontcolor = 'red'}}
local c_tt = nn.Identity()() -- c_tt := c_{t-1}
c_tt:annotate{graphAttributes = {color = 'red', fontcolor = 'red'}}

n_h = 4
n_i, n_f, n_o, n_c = n_h, n_h, n_h, n_h

local i_t = nn.Sigmoid()(nn.CAddTable()({
   nn.Linear(n_x, n_i)(x_t),
   nn.Linear(n_h, n_i)(h_tt)
}))
i_t:annotate{graphAttributes = {color = 'blue', fontcolor = 'blue'}}

local f_t = nn.Sigmoid()(nn.CAddTable()({
   nn.Linear(n_x, n_f)(x_t),
   nn.Linear(n_h, n_f)(h_tt)
}))
f_t:annotate{graphAttributes = {color = 'blue', fontcolor = 'blue'}}

local cc_t = nn.Tanh()(nn.CAddTable()({
   nn.Linear(n_x, n_c)(x_t),
   nn.Linear(n_h, n_c)(h_tt)
}))
cc_t:annotate{graphAttributes = {color = 'blue', fontcolor = 'blue'}}

local c_t = nn.CAddTable()({
   nn.CMulTable()({f_t, c_tt}),
   nn.CMulTable()({i_t, cc_t})
})
c_t:annotate{graphAttributes = {color = 'green', fontcolor = 'green'}}

local o_t = nn.Sigmoid()(nn.CAddTable()({
   nn.Linear(n_x, n_o)(x_t),
   nn.Linear(n_h, n_o)(h_tt),
   nn.Linear(n_c, n_o)(c_t)
}))
o_t:annotate{graphAttributes = {color = 'blue', fontcolor = 'blue'}}

local h_t = nn.CMulTable()({o_t, nn.Tanh()(c_t)} )
h_t:annotate{graphAttributes = {color = 'green', fontcolor = 'green'}}

nngraph.annotateNodes()
LSTM_module = nn.gModule({c_tt, h_tt, x_t}, {c_t, h_t})

pcall(function()
   inTable = {torch.zeros(n_c), torch.zeros(n_h), xv[1]}
   outTable = LSTM_module:forward(inTable)
end)
graph.dot(LSTM_module.fg, 'LSTM', 'LSTM')

-- Call as getParameters(LSTM_module, 20) if 20 is still a Linear
function getParameters(model, node)
   for a, b in ipairs(model.forwardnodes) do
      if b.id == node then
         print(c.green('Node ' .. node .. ': ' .. tostring(b.data.module)))
         print(c.blue('\nWeights:'))
         print(b.data.module.weight)
         print(c.blue('Bias:'))
         print(b.data.module.bias)
         return
      end
   end
end