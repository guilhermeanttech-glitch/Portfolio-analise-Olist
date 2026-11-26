USE DBOlist;

-- 1 Qual a receita, numero de vendas e ticket médio da empresa? Sem frete incluso.
SELECT 
SUM(i.price) AS receita_total, 
COUNT(DISTINCT o.order_id) AS total_de_vendas, 
ROUND((SUM(i.price)/COUNT(DISTINCT o.order_id)), 2) AS ticket_medio
FROM order_items i
JOIN orders o 
ON o.order_id=i.order_id
WHERE o.order_status = 'delivered';
-- Considerando apenas o preço bruto do produto de pedidos com status de 'entregue', a receita é de 13 milhões, com 96478 vendas e um ticket médio de 137.04.

-- 2 Quais estados mais geraram receita? Qual o numero de pedidos e seu ticket medio?
SELECT 
SUM(i.price) AS receita, 
COUNT(DISTINCT o.order_id) AS total_de_vendas, 
ROUND((SUM(i.price)/COUNT(DISTINCT o.order_id)), 2) AS ticket_medio,
ROUND(100 * SUM(i.price) / SUM(SUM(i.price)) OVER(), 2) AS porcentagem,
c.customer_state AS estado
FROM order_items i
JOIN orders o 
ON o.order_id=i.order_id
JOIN customers c
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY estado
ORDER BY receita DESC;
-- SP, o estado que apresenta mais vendas apresenta uma receita de 5 milhões, seguido de RJ com 1.7 milhões, MG com 1.5 milhões e RS com 728 mil.


-- 3 Qual o receita mensal da empresa e sua variação percentual em comparação ao mês anterior? De 2017 para frente.
WITH receita_mensal AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS periodo, 
SUM(i.price) AS receita
FROM orders o 
JOIN order_items i ON o.order_id = i.order_id
WHERE order_status = 'delivered' 
AND o.order_purchase_timestamp >= '2017-01-01'
GROUP BY periodo
)
SELECT receita, 
ROUND((receita - LAG(receita) OVER(ORDER BY periodo)) / LAG(receita) OVER(ORDER BY periodo) * 100, 2) AS variacao_porcentagem,
periodo
FROM receita_mensal
ORDER BY periodo;
-- Houve um aumento muito grande na receita em Fevereiro de 2017, um grande crescimento de vendas em Maio de 2017 em 43% e outro
-- em Novembro de 2017 em 52% devido a Black Friday, por isso a aparente queda de vendas no mes seguinte, porque é uma normalização após de Black Friday.

-- 4 Quantos pedidos foram de recompra?
SELECT 
COUNT(DISTINCT c.customer_id) AS total_pedidos,
COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT c.customer_unique_id) AS pedidos_de_recompra
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE order_status = 'delivered';
-- O número de pedidos de recompra é extremamente baixo. Dos 96 mil pedidos, apenas 3120 são de recompra além do primeiro de cada cliente.

-- A view a seguir sera usada para filtrar tipos de cliente(compra unica e recorrentes)
CREATE OR REPLACE VIEW sep AS 
SELECT 
o.order_id,
o.customer_id,
c.customer_unique_id, 
COUNT(*) OVER(PARTITION BY c.customer_unique_id) AS frequencia 
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id WHERE order_status = 'delivered';

-- 5 Qual a distribuição de notas entre clientes de compra unica e recorrentes?
SELECT ROUND((100 * COUNT(*)/SUM(COUNT(*)) OVER()), 2) AS total_geral,
ROUND((100 * COUNT(CASE WHEN sep.frequencia = 1 THEN 1 END)/SUM(COUNT(CASE WHEN sep.frequencia = 1 THEN 1 END)) OVER()), 2) AS compra_unica,
ROUND((100 * COUNT(CASE WHEN sep.frequencia > 1 THEN 1 END)/SUM(COUNT(CASE WHEN sep.frequencia > 1 THEN 1 END)) OVER()), 2) AS recorrentes,
r.review_score as nota
FROM order_reviews r
JOIN orders o ON o.order_id = r.order_id
JOIN sep ON o.customer_id = sep.customer_id
GROUP BY r.review_score
ORDER BY review_score DESC;
-- A nota entre os recorrentes é melhor, mas surpreendentemente, a variação de nota entre clientes de compra única e clientes recorrentes é mínima.
-- 62% de recorrentes deram nota 5 contra 59% de compra unica que deram nota 5.

-- 6 Quais as categorias que mais geram receita entre todos os clientes e os recorrentes?
WITH rank_geral AS (
SELECT p.product_category_name AS categoria_geral, 
SUM(i.price) AS receita_geral,
ROW_NUMBER() OVER(ORDER BY SUM(i.price) DESC) AS posicao
FROM products p 
JOIN order_items i ON i.product_id = p.product_id
JOIN orders o ON o.order_id = i.order_id
JOIN sep ON sep.customer_id = o.customer_id
GROUP BY p.product_category_name
), 
rank_recorrentes AS (
SELECT p.product_category_name AS categoria_recorrentes, 
SUM(i.price) AS receita_recorrentes,
ROW_NUMBER() OVER(ORDER BY SUM(i.price) DESC) AS posicao
FROM products p 
JOIN order_items i ON i.product_id = p.product_id
JOIN orders o ON o.order_id = i.order_id
JOIN sep ON sep.customer_id = o.customer_id
WHERE frequencia > 1
GROUP BY p.product_category_name
)
SELECT g.categoria_geral, 
g.receita_geral, 
r.categoria_recorrentes, 
r.receita_recorrentes
FROM rank_geral g
LEFT JOIN rank_recorrentes r 
ON g.posicao = r.posicao;
-- Algumas das categorias que mais geram receita entre clientes no geral é a mesma dos clientes recorrentes,
-- como cama, mesa, banho, esporte e lazer.
-- Porque isso é importante?
-- Se conseguirmos identificar oque causa retenção de clientes e as recompras, poderemos repetir esse padrão e ter um impacto maior na receita geral.