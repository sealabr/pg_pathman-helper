# pg_pathman-helper
Ajuda no pg_pathman / Help pg_pathman

Descritivo tudo sobre pg_patman...

pg_pathman:
https://github.com/postgrespro/pg_pathman

Data Rotation With `pg_pathman`

https://zilder.github.io/blog/2016/10/21/data-rotation-with-pg-pathman/

How Does Pg_pathman Handle Filter Conditions?

http://akorotkov.github.io/blog/2016/03/14/pg_pathman-condition-processing/

performance particionmento normal X pg_pathman

http://postgrespro.livejournal.com/48364.html

perfomance particionamento do 'concorrente nativo' pg_parTman

http://akorotkov.github.io/blog/2016/03/18/pg_pathman-update-delete-benchmark/

# LEIS DE PARTICIONAMENTO DE TABELAS
- a coluna de referência de particionamento não pode ser null ou seja... o atributo do campo só pode ser 'NOT NULL'
- a tabela não pode ter chaves estrangeiras, ou seja, tabela particionada não podem ser apontada por chave estrangeira, mais nada impede de ter um id_agente, por exemplo.
- a tabela não poder set temporária, view, view temp.
- não pode particionar tabelas já particionadas, ou seja, o filho não pode ter dois pais.
- ver a real necessidade de particionamento pois nem sempre é a solução do problema, sempre pesquisar, testar, homologar.

Particionar significa dividir uma grande tabela em pedaços menores. 
Cada linha dessa tabela é movida para uma única partição de acordo com a chave de particionamento. 
O PostgreSQL suporta o particionamento via herança de tabela: cada partição deve ser criada como uma tabela subordinada com 
CHECK CONSTRAINT. Por exemplo:

```sql
CREATE TABLE test (id SERIAL PRIMARY KEY, title TEXT);
CREATE TABLE test_1 (CHECK ( id >= 100 AND id < 200 )) INHERITS (test);
CREATE TABLE test_2 (CHECK ( id >= 200 AND id < 300 )) INHERITS (test);
```

Apesar da flexibilidade, essa abordagem força o banco a realizar uma pesquisa exaustiva e a 
verificar restrições em cada partição para determinar se ela deve estar presente no plano ou não. 
Grande quantidade de partições pode resultar em planejamento significativo sobrecarga.

O módulo (pg_pathman) possui funções de gerenciamento de partição e mecanismo de planejamento otimizado que utiliza o conhecimento da estrutura das partições. 
Armazena a configuração de particionamento na tabela pathman_config; 
Cada linha contém uma única entrada para uma tabela particionada (nome da relação, coluna de particionamento e seu tipo). 
Durante o estágio de inicialização o módulo pg_pathman armazena em cache algumas informações sobre partições filho na memória compartilhada, 
que é usada posteriormente para a construção do plano. 
Antes de executar uma consulta SELECT, pg_pathman atravessa a árvore de condições em busca de expressões como 
'VARIABLE OP CONST' onde VARIABLE é partitioning key e 'OP' é o operador ( =, <, <=, >, >=) e 'CONST' é o valor
EX.: 'WHERE id = 150'

## pg_pathman RANGE X HASH ##

RANGE 	- Mapeia linhas para partições usando intervalos de chave de particionamento atribuídos a cada partição. 
A otimização é obtida usando o algoritmo de busca binário;
HASH 	- Mapeia linhas para partições usando uma função de hash genérica.

## Destaques do recurso ##

- Esquemas de particionamento HASH e RANGE;
- Gerenciamento de partições automático e manual;
- Suporte para tipos integer, floating, date e outros tipos, including domains;
- Planejamento efetivo de consultas para tabelas particionadas (JOINs, subselects etc);
- RuntimeAppend & RuntimeMergeAppend custom plan nodes para escolher partições em tempo de execução;
- PartitionFilter: uma substituição drop-in eficiente para gatilhos INSERT;
- Criação automática de partições para novos dados INSERTed (somente para particionamento RANGE);
- Melhor COPY FROM \ TO declaração que é capaz de inserir linhas diretamente em partições;
- UPDATE desencadeia geração fora da caixa (será substituído por nós personalizados também);
- Callbacks definidos pelo usuário para manipulação de evento de criação de partição;
- Particionamento simultâneo de tabelas sem bloqueio;
- Suporte FDW (Foreign data wrappers) (foreign partitions);
- Vários GUC toggles e configurações.

## Funções Disponíveis HASH ##

```sql
create_hash_partitions(relation         REGCLASS, 				'TABELA PARTICIONAR'
                       attribute        TEXT,					'ATRIBUTO DE PARTICIONAMENTO'
                       partitions_count INTEGER,				'CRIAR X PARTICIONAMENTOS'
                       partition_data   BOOLEAN DEFAULT TRUE,	'Se partition_data for true, então todos os dados serão automaticamente copiados da tabela pai para partições'
                       partition_names  TEXT[] DEFAULT NULL,	
                       tablespaces      TEXT[] DEFAULT NULL)
 ```
`		       
					   
Executa o particionamento HASH para a relação por um atributo de chave inteiro. 
O parâmetro partitions_count especifica o número de partições a serem criadas; 
Não pode ser alterado posteriormente. Se partition_data for true, então todos os dados serão automaticamente copiados da tabela pai para partições. 
Observe que a migração de dados pode demorar um pouco para terminar ea tabela será bloqueada até que a transação seja confirmada. 
Consulte partition_table_concurrently () para obter uma maneira livre de bloqueio para migrar dados. 
O callback de criação de partição é chamado para cada partição se definido previamente (veja set_init_callback())

## Funções Disponíveis RANGE ##


```sql
create_range_partitions(relation       REGCLASS,				'TABELA PARTICIONAR'
                        attribute      TEXT,					'ATRIBUTO DE PARTICIONAMENTO'
                        start_value    ANYELEMENT,
                        p_interval     ANYELEMENT / INTERVAL,
                        p_count        INTEGER DEFAULT NULL
                        partition_data BOOLEAN DEFAULT TRUE)
 ```
						
O parâmetro start_value especifica o valor inicial, p_interval define o intervalo padrão para partições criadas automaticamente 
ou partições criadas com append_range_partition () ou prepend_range_partition () 
(se NULL, então o recurso de criação de partição automática não funcionará), P_count é o número de partições premade 
se não for definido, pg_pathman tenta determinar com base em valores de atributo). O callback de criação de partição é chamado para cada partição se 
definido previamente.

```sql
create_partitions_from_range(relation       REGCLASS,			'TABELA PARTICIONAR'
                             attribute      TEXT,				'ATRIBUTO DE PARTICIONAMENTO'
                             start_value    ANYELEMENT,
                             end_value      ANYELEMENT,
                             p_interval     ANYELEMENT / INTERVAL,
                             partition_data BOOLEAN DEFAULT TRUE)
 ```
						
Executa o particionamento RANGE do intervalo especificado para a relação por atributo de chave de particionamento. 
O callback de criação de partição é chamado para cada partição se definido previamente.


