-- Parte1 do Projeto de Base De Dados

-- 1) O import das tables foi feita atraves do dBVisualizer

-- 2) Criados indices
ALTER TABLE load_song ADD INDEX musica_idS(musica_id);
ALTER TABLE load_song_artists ADD INDEX musica_idS(musica_id);
ALTER TABLE load_song_detail ADD INDEX musica_idS(musica_id);


-- 3.1) Retirados Espacos 
UPDATE load_song SET musica_id = TRIM(musica_id);
UPDATE load_song SET titulo = TRIM(titulo);
UPDATE load_song SET ano = TRIM(ano);

UPDATE load_song_artists SET musica_id = TRIM(musica_id);
UPDATE load_song_artists SET artists = TRIM(artists);

UPDATE load_song_detail SET musica_id = TRIM(musica_id);
 
-- 3.2, 3.3) Retirados ",[,]
UPDATE load_song SET titulo = REPLACE(titulo,'"','');
UPDATE load_song SET titulo = REPLACE(titulo,'[','');
UPDATE load_song SET titulo = REPLACE(titulo,']','');

UPDATE load_song_artists SET artists = REPLACE(artists,'"','');
UPDATE load_song_artists SET artists = REPLACE(artists,'[','');
UPDATE load_song_artists SET artists = REPLACE(artists,'\'','');
UPDATE load_song_artists SET artists = REPLACE(artists,']','');


-- 3.4) Determina quantos artistas existe em cada linha do Load_artists
SELECT artists, 
LENGTH(artists) - LENGTH(REPLACE(artists,',',''))+1 AS 'Numero de Artistas'
FROM load_song_artists
ORDER BY LENGTH(artists) - LENGTH(REPLACE(artists,',',''))+1  DESC; 


-- 4.1) Ira dar output, dos ID's repetidos, e quantas vezes estao repetidos
SELECT musica_id, COUNT(musica_id) AS 'Numero de vezes que o ID esta repetido'
FROM load_song
GROUP BY musica_id
HAVING COUNT(musica_id) > 1;

SELECT musica_id, COUNT(musica_id) AS 'Numero de vezes que o ID esta repetido'
FROM load_song_artists
GROUP BY musica_id
HAVING COUNT(musica_id) > 1;

SELECT musica_id, COUNT(musica_id) AS 'Numero de vezes que o ID esta repetido'
FROM load_song_detail
GROUP BY musica_id
HAVING COUNT(musica_id) > 1 ;


-- 4.2) Eliminar os dados repetidos 
ALTER TABLE load_song ADD id INT PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE load_song_artists ADD id INT PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE load_song_detail ADD id INT PRIMARY KEY AUTO_INCREMENT;

select musica_id
        from load_song_artists
        GROUP BY musica_id
        HAVING COUNT(musica_id) > 1
        
DELETE artista1 FROM load_song artista1 
JOIN load_song artista2 
WHERE artista1.musica_id = artista2.musica_id AND artista1.id > artista2.id;

DELETE artista1 FROM load_song_artists artista1 
JOIN load_song_artists artista2 
WHERE artista1.musica_id = artista2.musica_id AND artista1.id > artista2.id;

DELETE artista1 FROM load_song_artists artista1 
JOIN load_song_artists artista2 
WHERE artista1.musica_id = artista2.musica_id AND artista1.id > artista2.id;

--5.1) Detectar musica_id de load_song_detail que não existem em load_song e eliminar; 
DELETE e FROM load_song_detail e WHERE NOT EXISTS (SELECT * FROM load_song r WHERE e.musica_id = r.musica_id);

--5.2) Juntar musica com detalhe de musica usando o musica_id que já não tem valores repetidos. Só devem aparecer dados que existam nas duas tabelas;  
INSERT INTO musica_relacionada (musica_id1,musica_id2,descricao)
SELECT t1.musica_id,t2.musica_id,"" FROM load_song_detail t1
INNER JOIN load_song t2 ON t1.musica_id = t2.musica_id

--5.3) Em load_song_artists adicione a coluna artista_id e atribua valores com incrementos de 100 unidades. Em Oracle usar sequências e em MySQL usar variáveis de sessão; 
 
UPDATE load_song_artists  s ,(select @row_count:=0) as init set artista_id = (@row_count:=@row_count+100);  


-- --5.4) Encontrar um mecanismo que permita listar o primeiro artista, ou o segundo, ou o nésimo, juntamente com com musica_id e artista_id inserido no passo anterior. 
--O artista da coluna 1 será artista_id+1, o da coluna 2 será artista_id+2, etc. 
--Foi por isto que os valores de artista_id têm incrementos de 100 unidades entre linhas. Este query será usado para insert na tabela artista; 
---Separacao

create table ArtistsSolo(
        artista_id int(10) not null AUTO_INCREMENT PRIMARY KEY, 
        id varchar(2000),
        Artists varchar(2000)
);

insert Into ArtistsSolo (id,Artists) select 
  Teste.artista_id ,
  SUBSTRING_INDEX(SUBSTRING_INDEX(Teste.artists, ',', numbers.n), ',', -1) artists 
from 
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN Teste
  on CHAR_LENGTH(Teste.artists)
     -CHAR_LENGTH(REPLACE(Teste.artists, ',', ''))>=numbers.n-1
order by
  id, n;

drop  function pos_artist
@delimiter %%%;
CREATE FUNCTION pos_artist(artist varchar(600), string varchar(2000))
RETURNS int deterministic

BEGIN

   DECLARE current_str varchar(2000);
   DECLARE pos int(10);

   set current_str = string;
   set pos = 1;

   label:
   while POSITION(artist in current_str) != 1 DO
      set current_str = substring(current_str, 2);
        if STRCMP(LEFT(current_str, 1), ",") = 0 then
                set pos = pos + 1;
        END IF;
      END
   while label;
   RETURN pos;

END;%%%
@delimiter ; 
%%%

update Teste
inner join ArtistsSolo grupo_artistas on grupo_artistas.id = Teste.artista_id
set Teste.artista_id = Teste.artista_id +  pos_artist(Teste.artists, grupo_artistas.Artists)







create table ArtistsSolo(
        artista_id int(10) not null AUTO_INCREMENT PRIMARY KEY, 
        id varchar(2000),
        Artists varchar(2000)
);

---------------------------------------------------------------
@delimiter %%%;
CREATE PROCEDURE procedure_load_song_artists()
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
        declare x INT default 0;
        SET x = 0;

        WHILE x <= 28 DO

                insert into ArtistsSolo(id, Artists)
                select id, trim(SUBSTRING_INDEX(SUBSTRING_INDEX(artists,',', x + 1), ',', -1))
                from Artists
                where 
                        amount_of_commas(artists) >= x and amount_of_commas(trim(SUBSTRING_INDEX(SUBSTRING_INDEX(artists,',', x + 1), ',', -1))) = 0;

                set x = x + 1;
         end while;
END;
%%%
@delimiter ; 
%%%
call procedure_load_song_artists()




call dividirArtista()


@delimiter %%%;
CREATE Procedure dividirArtista()
 NOT DETERMINISTIC
    READS SQL DATA
BEGIN
      DECLARE pos int(10);
      set pos = 1;
    select length(replace(str, ',', ', ')) - length(str)
    as artists
, while (pos < 28) do
       substring_index(substring_index(str,',',pos),',',-1) as 'pos'
        SET pos = pos+1;
        end while;
from (
    select replace(concat(artists,','),',,',',') as str
    from load_song_artists
) normalized;

END;
%%%
@delimiter ; 
%%%


@delimiter %%%;
CREATE FUNCTION pos_artist(artist varchar(600), string varchar(2000))
RETURNS int(10) deterministic

BEGIN

   DECLARE current_str varchar(2000);
   DECLARE pos int(10);

   set current_str = string;
   set pos = 1;

   
   RETURN pos;

END %%%
@delimiter ; 
%%%

--5.5)Escrever query que mostra o artista_id com musica_id. 
--Começamos pelo artista que está na primeira posição, depois na segunda e assim sucessivamente até à posição n. 
--Este query será usado para inserir dados em contribuição de artista; 



--6) Criar todas as tabelas do modelo incluindo restrições PK, UK, NOT NULL, CHK e FK. Defina as que entender necessárias tendo em conta o modelo apresentado. 
INSERT INTO musica_relacionada (musica_id1,musica_id2,descricao)
SELECT t1.musica_id,t2.musica_id,"" FROM load_song_detail t1
INNER JOIN load_song t2 ON t1.musica_id = t2.musica_id






INSERT INTO musica (id,titulo,ano,duracao,letra_explicita,popularidade,grau_dancabilidade,grau_vivacidade,volume_som_medio)
SELECT t2.musica_id,t2.titulo,t2.ano,t1.duracao,t1.letra_explicita,t1.popularidade,t1.grau_dancabilidade,t1.grau_vivacidade,t1.volume_som_medio FROM load_song_detail t1
 JOIN load_song t2 ON t1.musica_id = t2.musica_id



call adicionaFaixa();

INSERT INTO album (id,nome,data_lancamento) values (1,"Album1",2000);
INSERT INTO album (id,nome,data_lancamento) values (2,"Album2",2000);
INSERT INTO album (id,nome,data_lancamento) values (3,"Album3",2000);
INSERT INTO album (id,nome,data_lancamento) values (4,"Album4",2000);
INSERT INTO album (id,nome,data_lancamento) values (5,"Album5",2000);






create table Teste ( 
        musica_id varchar(600),
        artists varchar(600),
        artista_id int,
        id int primary key
        );
        
insert into Teste values("4OdhWe5GZTkwAuNXLQZImM","The Jacksons",100,1);
insert into Teste values("48y9vlCgSvliuouRRGFlRG","Beastie Boys, The Prunes",200,2);
insert into Teste values("6KPkjg3gBRxx3An5BVSBo9","Soda Stereo",300,3);












@delimiter %%%;
CREATE FUNCTION musicaAno(anoInput int(10))
        RETURNS int(10) deterministic

BEGIN
        declare varOutput int ;
       select count(ano)into varOutput FROM musica WHERE ano=anoInput ;
       return varOutput;

END;%%%
@delimiter ; 
%%%

select musicaAno(2020);

SELECT count(ano), ano FROM musica GROUP BY ano HAVING COUNT(ano) > 1 ORDER BY count(ano) DESC;

        ----14.5
        --criacao de rotulos
        @delimiter %%%;
        CREATE Procedure insertRotulo()
         NOT DETERMINISTIC
            READS SQL DATA
        BEGIN 
                DECLARE x int(10);
                set x=1;
                while x<=20 do
                
                insert into rotulo values(x,"");
                set x=x+1;
                
               end while;
        END;
        %%%
        @delimiter ; 
        %%%
        call insertRotulo()



--14.7
@delimiter %%%;
CREATE FUNCTION musicaAno2(numero int(10) ,anoPrimeiro int(10) ,anoSegundo int(10))
        RETURNS int(10) deterministic

BEGIN
        declare varOutput int ;
        select count(ano) into varOutput FROM musica WHERE (ano=anoInput and ano>=anoPrimeiro and ano<=anoSegundo) limit numero;
 
        return varOutput;
END;%%%
@delimiter ; 
%%%

musicaAno2(1,2000,2020);









@DELIMITER $$  
CREATE Function LoopOutput( START INT,INCREMENT INT,FINISH INT)
BEGIN
      DECLARE TEMP_INC INT default 0
      set TEMP_INC=0;
      while TEMP_INC != FINISH do
         
         select substring_index('1,2,3,4,5,6,7,8,9,0',',',1)
        SET TEMP_INC := TEMP_INC + INCREMENT
   END while
END $$
@delimiter $$;
CALL LoopOutput(1, 1, 10)


select length(replace(str, ',', ', ')) - length(str)
    as artists
, substring_index(substring_index(str,',',1),',',-1) as Loc1
, substring_index(substring_index(str,',',2),',',-1) as Loc2
, substring_index(substring_index(str,',',3),',',-1) as Loc3
, substring_index(substring_index(str,',',4),',',-1) as Loc4
, substring_index(substring_index(str,',',5),',',-1) as Loc5
, substring_index(substring_index(str,',',6),',',-1) as Loc6
, substring_index(substring_index(str,',',7),',',-1) as Loc7
, substring_index(substring_index(str,',',8),',',-1) as Loc8
, substring_index(substring_index(str,',',9),',',-1) as Loc9
, substring_index(substring_index(str,',',10),',',-1) as Loc10
, substring_index(substring_index(str,',',11),',',-1) as Loc11
, substring_index(substring_index(str,',',12),',',-1) as Loc12
, substring_index(substring_index(str,',',13),',',-1) as Loc13
, substring_index(substring_index(str,',',14),',',-1) as Loc14
, substring_index(substring_index(str,',',15),',',-1) as Loc15
, substring_index(substring_index(str,',',16),',',-1) as Loc16
, substring_index(substring_index(str,',',17),',',-1) as Loc17
, substring_index(substring_index(str,',',18),',',-1) as Loc18
, substring_index(substring_index(str,',',19),',',-1) as Loc19
, substring_index(substring_index(str,',',20),',',-1) as Loc20
, substring_index(substring_index(str,',',21),',',-1) as Loc21
, substring_index(substring_index(str,',',22),',',-1) as Loc22
, substring_index(substring_index(str,',',23),',',-1) as Loc23
, substring_index(substring_index(str,',',24),',',-1) as Loc24
, substring_index(substring_index(str,',',25),',',-1) as Loc25
, substring_index(substring_index(str,',',26),',',-1) as Loc26
, substring_index(substring_index(str,',',27),',',-1) as Loc27
, substring_index(substring_index(str,',',28),',',-1) as Loc28


from (
    select replace(concat(artists,','),',,',',') as str
    from load_song_artists 
) normalized





--5.4

create table ArtistaSeparado(
        artista_id int(10) not null AUTO_INCREMENT PRIMARY KEY, 
        Artists varchar(2000)
);

create function amount_of_commas(string varchar(2000))
returns int(10) deterministic
return CHAR_LENGTH(string) - CHAR_LENGTH( REPLACE ( string, ',', '') );

@delimiter %%%;
CREATE PROCEDURE proc_separa_artistas()
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
        declare x INT default 0;
        SET x = 0;

        WHILE x <= 28 DO

                set x = x + 1;
                insert into ArtistaSeparado(Artists)
                select trim(SUBSTRING_INDEX(SUBSTRING_INDEX(artists,',', x ), ',', -1))
                from load_song_artists
                where 
                        amount_of_commas(artists) >= x and amount_of_commas(trim(SUBSTRING_INDEX(SUBSTRING_INDEX(artists,',', x), ',', -1))) = 0;


         end while;
END;
%%%
@delimiter ; 
%%%

call proc_separa_artistas()








select * from load_song_artists artista1 inner join artista artista2 on artista1.artists=artista2.nome_artistico order by artista2.id asc






insert into contribuicao_artista (artista_id,musica_id,tipo_contribuicao_id,descricao)
select b.id,a.musica_id,c.id,"" from load_song_artists a join artista b join tipo_contribuicao c

insert into tipo_contribuicao (id,descricao) values(1,"")



CREATE TABLE musica(
        id varchar(22),
        titulo varchar(200),
        ano int(4),
        duracao int(10),
        letra_explicita tinyint(4),
        popularidade int(3),
        grau_dancabilidade double,
        grau_vivacidade double,
        volume_som_medio double,
        duracaoCalc varchar(20) null,
        PRIMARY KEY (id)
);
ALTER TABLE 
    musica ADD (duracaoCalc VARCHAR(100) null) 
    
insert into musica (id,titulo,ano,duracao,letra_explicita,popularidade,grau_dancabilidade,grau_vivacidade,volume_som_medio) values(5,"aa",2020,2,1,1,1.0,1.0,1.0);

@delimiter %%%;
CREATE  Procedure calcDuracaoMusica()
 NOT DETERMINISTIC
    READS SQL DATA
    begin
  UPDATE musica
        SET duracaoCalc = IF(ROUND(duracao / 1000 / 60) > 0 , CONCAT(" ",ROUND(duracao / 1000 / 60) , ":",ROUND((duracao / 1000) % 60)) , Concat(" 0 : ",ROUND((duracao / 1000) % 60)));
    
end;%%%
@delimiter; 
 call calcDuracaoMusica()








CREATE TABLE IF NOT EXISTS artistasLoaded
        select length(replace(str, ',', ', ')) - length(str) as artists
        , substring_index(substring_index(str,',',1),',',-1) as Loc1
        , substring_index(substring_index(str,',',2),',',-1) as Loc2
        , substring_index(substring_index(str,',',3),',',-1) as Loc3
        , substring_index(substring_index(str,',',4),',',-1) as Loc4
        , substring_index(substring_index(str,',',5),',',-1) as Loc5
        , substring_index(substring_index(str,',',6),',',-1) as Loc6
        , substring_index(substring_index(str,',',7),',',-1) as Loc7
        , substring_index(substring_index(str,',',8),',',-1) as Loc8
        , substring_index(substring_index(str,',',9),',',-1) as Loc9
        , substring_index(substring_index(str,',',10),',',-1) as Loc10
        , substring_index(substring_index(str,',',11),',',-1) as Loc11
        , substring_index(substring_index(str,',',12),',',-1) as Loc12
        , substring_index(substring_index(str,',',13),',',-1) as Loc13
        , substring_index(substring_index(str,',',14),',',-1) as Loc14
        , substring_index(substring_index(str,',',15),',',-1) as Loc15
        , substring_index(substring_index(str,',',16),',',-1) as Loc16
        , substring_index(substring_index(str,',',17),',',-1) as Loc17
        , substring_index(substring_index(str,',',18),',',-1) as Loc18
        , substring_index(substring_index(str,',',19),',',-1) as Loc19
        , substring_index(substring_index(str,',',20),',',-1) as Loc20
        , substring_index(substring_index(str,',',21),',',-1) as Loc21
        , substring_index(substring_index(str,',',22),',',-1) as Loc22
        , substring_index(substring_index(str,',',23),',',-1) as Loc23
        , substring_index(substring_index(str,',',24),',',-1) as Loc24
        , substring_index(substring_index(str,',',25),',',-1) as Loc25
        , substring_index(substring_index(str,',',26),',',-1) as Loc26
        , substring_index(substring_index(str,',',27),',',-1) as Loc27
        , substring_index(substring_index(str,',',28),',',-1) as Loc28
        , artista_id as artista_id
        , musica_id as musica_id
        
        from (
            select replace(concat(artists,','),',,',',') as str
            ,artista_id as artista_id
            ,musica_id as musica_id
            from load_song_artists
        ) normalized


create table test(
        artists_id int,
        artists varchar(2000),
        musica_id varchar(2000)
);


ALTER TABLE test ORDER BY artists_id ASC;


@delimiter %%%;
Create Procedure createAAA()
NOT DETERMINISTIC
    READS SQL DATA

BEGIN
        declare x INT default 28;

        WHILE (x > 1) DO

                
                INSERT INTO test ( artists_id,artists, musica_id) 
                SELECT artista_id + x,Concat("Loc",x) ,musica_id
                FROM artistasLoaded
                WHERE Concat("Loc",x)   != '';

                set x = x - 1;
         end while;
END;%%%
@delimiter ; 
%%%
delete test
call createAAA()

@delimiter %%%;
CREATE  Procedure calcDuracaoMusica()
 NOT DETERMINISTIC
    READS SQL DATA
    begin
  UPDATE musica
        SET duracaoCalc = IF(ROUND(duracao / 1000 / 60) > 0 , CONCAT(" ",ROUND(duracao / 1000 / 60) , ":",ROUND((duracao / 1000) % 60)) , Concat(" 0 : ",ROUND((duracao / 1000) % 60)));
    
end;%%%
@delimiter; 



insert into contribuicao_artista
SELECT artista2.id,artista1.musica_id,tipo.id,"" FROM load_song_artists artista1 
INNER JOIN artista artista2 join tipo_contribuicao tipo ON artista1.musica_id=artista2.id ORDER BY artista2.id ASC;



SELECT musica_id, COUNT(musica_id) AS 'Numero de vezes que o ID esta repetido'
FROM load_song_detail
GROUP BY musica_id
HAVING COUNT(musica_id) > 1 ;

INSERT INTO rotulo_artista (artista_id,rotulo_id)
select t1.id,t2.id FROM artista t1
inner JOIN rotulo t2 where t1.id = t2.id

--proc com isto

SELECT nome_artistico , COUNT(c.artista_id) 
FROM contribuicao_artista c inner join artista a where c.artista_id = a.id
GROUP BY c.artista_id
HAVING COUNT(c.artista_id) = 1 ;




--14.9


@delimiter %%%;
CREATE Procedure temasNumIntervalo( numero INT,primeiroNum INT,segundoNum INT)
BEGIN
        SELECT musica_id, COUNT(musica_id) 
        FROM contribuicao_artista c inner join artista a where c.artista_id = a.id
        GROUP BY c.artista_id
        HAVING COUNT(c.artista_id) > primeiroNum and COUNT(c.artista_id)<segundoNum limit numero;
        
END;%%%
@delimiter ; 
%%%
call temasNumIntervalo(10,2,4)


--14.11
@delimiter %%%;
CREATE Procedure artista_Ano(primeiroNum INT,segundoNum INT)
BEGIN

        select a.nome_artistico, b.ano from artista a inner join musica b where a.id=b.id and (b.ano>=primeiroNum and b.ano<=segundoNum);

END;%%%
@delimiter ; 
%%%
















