# EMBERQUILL — Cavaleiros do Grimório

> Roguelite de ação 3D estilizado, 1–4 jogadores em co-op local, construído em Godot 4.7.
> Modelos e animações gerados por script no Blender (bpy). Feitiços compostos como frases de glifos.

---

## 1. Premissa

O Grande Grimório está sendo reescrito por dentro. Tinta viva — as **Erratas** — escapou das
margens e corrompe capítulo após capítulo. Os **Cavaleiros-Pavio** são pequenos guardiões com uma
chama acesa no elmo (a *brasa*) e um grimório pessoal onde **escrevem os próprios feitiços**.

Cada sala é uma **página** do livro. Quando a página abre, o cenário se levanta como num livro
pop-up; quando a sala é vencida, a página vira.

## 2. Pilares

1. **O feitiço é uma frase.** O jogador não escolhe feitiços prontos: ele escreve. Glifos são lidos da
   esquerda para a direita como uma oração, e a gramática gera variações infinitas.
2. **Cada feitiço tem rosto próprio.** Nome, sigilo, cores, forma do projétil, rastro, partículas, som
   e animação de conjuração são derivados da composição e da semente do feitiço.
3. **Combate rápido e legível**, no espírito de Ember Knights: esquiva com esquiva perfeita, combos
   corpo a corpo, recarga curta, telegráficos claros.
4. **Co-op como cidadão de primeira classe**: câmera compartilhada, reviver aliados, sinergias entre
   feitiços de jogadores diferentes (Aurora cura aliados, Vazio marca alvos para o time).
5. **Interface diegética, feita à mão**: pergaminho, nanquim, lacre de cera, fitas marcadoras.
   Nada de cartões genéricos com gradiente.

## 3. O que herdamos de Ember Knights (pesquisa)

| Ember Knights | Emberquill |
|---|---|
| 1–4 jogadores, local e online; câmera compartilhada que dá zoom out para caber todos | 1–4 locais, câmera que enquadra todos com limite (leash) |
| Armas com combo + habilidades com recarga + relíquias | Pena-espada (combo de 3 golpes) + 3 páginas de feitiço + relíquias |
| Esquiva perfeita recompensada por relíquias | Esquiva perfeita: câmera lenta, carga de "Tinta Viva" e ganchos para relíquias |
| Salas com seletores de recompensa (Relic/Skill Selector: escolher 1 de 3) | Portas com ícone da recompensa; escolha de 1 entre 3 glifos/relíquias |
| Sala de cura que revive todos os caídos | Página do Tinteiro: cura em "pool" compartilhado e revive |
| Reviver: estoque compartilhado de revives + revive grátis após chefes | Estoque de "Pavios Reserva" (meta) + reacender aliado de perto + revive após chefe |
| Hub (Nexus) com Ember Tree para melhorias permanentes pagas com Ember | Frontispício com o **Candelabro** (árvore de melhorias) pago com **Brasas** |
| Status: Burn, Freeze, Poison (acumula 1/2/4/8/16), Lightning | Brasa, Geada→Congelar, Peçonha (acumula dobrando), Tempestade, Vazio, Aurora |

## 4. O Grimório — gramática de feitiços

Cada jogador tem **3 páginas** (Feitiço I, II, III), cada uma com 4–8 espaços. Um feitiço é a
sequência de glifos da página. Há quatro classes de glifo:

### 4.1 Formas (o substantivo)
Definem como o feitiço existe no mundo.

| Glifo | Comportamento | Animação |
|---|---|---|
| Dardo | projétil rápido | estocada |
| Orbe | projétil lento e grande que atravessa causando dano contínuo | estocada |
| Nova | explosão radial ao redor do conjurador | golpe no chão |
| Lança | linha instantânea perfurante | estocada forte |
| Onda | crescente que avança e atravessa | varrida |
| Chuva | vários impactos caindo sobre a área alvo | braços ao alto |
| Satélites | orbes orbitando o conjurador | giro |
| Runa | armadilha que detona quando pisada | golpe no chão |
| Chakram | vai e volta atravessando | giro |
| Meteoro | impacto único, atrasado e enorme | braços ao alto |
| Vórtice | singularidade que puxa inimigos | estocada |
| Sentinela | torre que conjura sozinha | braços ao alto |
| Serpente | corrente sinuosa de segmentos que persegue | varrida |

### 4.2 Essências (o adjetivo)
Brasa (queima), Geada (lentidão → congelar), Tempestade (arco elétrico em cadeia), Vazio (marca:
+dano recebido e puxão), Peçonha (veneno que dobra por acúmulo), Aurora (cura aliados atingidos).

Duas essências diferentes na mesma oração **se fundem** (15 fusões), cada uma com nome, paleta e
reação própria: Vapor, Plasma, Chama Negra, Enxofre, Solar, Cristal, Entropia, Miasma, Prisma,
Fenda, Neurotoxina, Juízo, Praga, Eclipse, Seiva. A mesma essência repetida **intensifica**.

### 4.3 Inflexões (o advérbio)
Bifurcar, Eco, Buscar, Trespassar, Ricochete, Magnificar, Celeridade, Volátil, Persistir, Espelho,
Espiral, Suspensão, Sifão, Impacto, Aguçar, Atrair, Saltar, Égide. São acumuláveis.

### 4.4 Elos (a conjunção)
**Ao Tocar**, **Ao Findar**, **Ao Abater**, **Ao Pulsar**, **E Então**. Um elo encerra a oração atual
e transforma o que vem depois em *carga* disparada pelo evento. Cargas podem ter seus próprios elos
(até 3 níveis), o que gera cadeias como:

> *Dardo de Brasa bifurcado* — **ao tocar** — *Nova de Geada em eco* — **ao findar** — *Chuva de Tempestade*.

### 4.5 Regras de leitura
- Essências e inflexões se ligam à forma mais recente da oração; antes de qualquer forma, ficam
  "pendentes" e se ligam à próxima.
- Duas formas na mesma oração são conjuradas juntas (multiconjuração).
- Uma oração sem forma usa **Dardo** como forma implícita (o livro "completa" a frase, e a UI mostra isso).
- Custo: cada glifo tem peso de tinta; recarga = base da forma × multiplicadores × custo das cargas.
- Poder das cargas cai por profundidade (×0,65 por nível); há orçamento de eventos por conjuração para
  impedir explosões combinatórias de desempenho.

### 4.6 Identidade procedural
A partir da sequência de glifos é calculada uma **semente**. Dela derivam:
- **Nome** (gramática pt-BR com concordância de gênero, e inglês), p.ex. *"Agulha Ígnea Bifurcada"*.
- **Sigilo**: anéis, polígramas {n/k}, traços dos glifos em volta — desenhado em nanquim no livro e
  projetado no chão (círculo mágico) ao conjurar.
- **Visual**: paleta (essências/fusão), silhueta do núcleo (pontas, torção, pulsação), rastro,
  partículas por essência, deformação por inflexões.
- **Som**: camada da forma + camada da essência, com afinação derivada da semente.
- **Animação**: definida pela forma dominante e acelerada pela recarga.

## 5. Estrutura da expedição

- **Frontispício (hub)**: jogadores entram (co-op), testam feitiços no boneco de treino, gastam Brasas
  no Candelabro, abrem o Capítulo I.
- **Capítulos**: I — Bosque de Papel, II — Catacumbas de Cera, III — Mar de Nanquim. Cada um: páginas de
  combate, páginas especiais (Tinteiro/cura, Loja do Encadernador, Página de Elite) e chefe.
- Ao vencer uma página aparecem **2–3 portas** (fitas marcadoras) com o ícone da recompensa:
  glifo, relíquia, ouro, cura, loja, página extra (+1 espaço), elite.
- Morte ou vitória: volta ao hub com as Brasas coletadas.

## 6. Co-op local

- P1 teclado+mouse; P2 teclado (setas); controles 1–4. "Aperte para entrar" no hub.
- Câmera compartilhada: centróide dos vivos, zoom pela dispersão, jogadores presos à borda.
- Caído vira um **pavio apagado**; aliado perto reacende (segurar interação). Todos revivem após chefe.
- Cada jogador edita o próprio grimório num painel próprio (meia tela / quadrante), com cursor próprio.
- Sinergias: Aurora cura aliados, Vazio marca para o time, relíquias de proximidade.

## 7. Game feel

Hitstop proporcional ao dano, tremor por "trauma" (ruído), flash branco, squash & stretch, recuo e
knockback, números de dano em tinta, respingos que permanecem no chão da página, câmera lenta na
esquiva perfeita e na morte do chefe, zoom de impacto, vibração por controle, aberração cromática ao ser
atingido, vinheta em vida baixa, cenário que salta da página (pop-up), transição de virar página.

## 8. Direção de arte

- **Livro pop-up**: chão de pergaminho com escrita desbotada, cenário dobrável, abismo escuro com folhas
  flutuando além da página.
- Toon shading com contorno em nanquim (casco invertido), luz quente de vela, bloom contido.
- UI: pergaminho procedural, bordas desenhadas à pena, lacres de cera, capitulares iluminadas,
  tipografia serifada histórica (IM Fell, Cormorant) — assimetria intencional.

## 9. Referências pesquisadas

- Ember Knights — Steam, Xbox Wire ("How Ember Knights was Built from the Ground Up for Co-op"),
  wikis (Status Conditions, Skills, Special Rooms, Nexus).
- Mages of Mystralia — runas de Comportamento, Aumento e Gatilho (fonte da ideia de elos/cargas).
- Noita — blocos de conjuração, multicast, feitiços com gatilho que carregam outro feitiço.
- Magicraft — leitura sequencial da esquerda para a direita, modificadores afetando vizinhos.
- Magicka — fila de elementos e combinações (Vapor, Gelo) com prioridades.
- Wizard of Legend — arcana, relíquias, co-op local e ritmo de combate de mago.
- Hades — hierarquia tipográfica nas escolhas de recompensa, portas com ícone de recompensa.
- Vlambeer, *The Art of Screenshake* — hitstop, recuo, tremor, permanência de efeitos.
