local ls = require("luasnip")
local s = ls.snippet
-- local t = ls.text_node
local i = ls.insert_node
--local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

ls.add_snippets("tex", {
  s({ trig = "modelo", regTrig = true },
    fmta(
      [[
\documentclass[
	12pt,
	oneside,
	a4paper,
]{article}

\usepackage{prefeitura/ci}

%%%DOCUMENTO%%%

\begin{document}

\Cabecalho{<>}{<>}% código da CI/destinatário

\Assunto{%
    {<>}% digite o assunto da CI aqui
}%

Prezados,

<>

\Cumprimento

\Atenciosamente

\Assinaturas
{André Alexandre Aguiar,Agente em Atividades Administrativas}%
[Ana Caroline Emilio Weidt,Diretora de Ouvidoria]

\end{document}
      ]],
      { i(1), i(2), i(3), i(4) })),
})
