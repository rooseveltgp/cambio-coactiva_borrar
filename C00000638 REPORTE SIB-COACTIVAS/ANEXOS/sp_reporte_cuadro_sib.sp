set replication off
go
/*************************************************************************/
/*   Archivo:            sp_reporte_cuadro_sib.sp                        */
/*   Stored procedure:   sp_reporte_cuadro_sib                           */
/*   Base de datos:      cob_coactiva                                    */
/*   Producto:           Coactiva                                        */
/*   Disenado por:       Jacqueline Bulla                                */
/*   Fecha de escritura: 01-julio-2013                                   */
/*************************************************************************/
/*                               IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "COBISCORP", representantes exclusivos para el Ecuador de la     */
/*      "COBISCORP CORPORATION".                                         */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de COBISCORP o su representante.           */
/*************************************************************************/
/*                                PROPOSITO                              */
/*   Este programa genera datos para el reporte enviado a la SIB         */
/*************************************************************************/
/*                               OPERACIONES                             */
/*   OPER. OPCION                     DESCRIPCION                        */
/*     G                  Generacion de datos para reporte               */
/*     P                  Presentacion de los datos generados            */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*   FECHA            AUTOR                      RAZON                   */
/*   01-Jul-2013      Jacqueline Bulla     Version Inicial               */
/*   05-Jun-2017      Erik Cespedes        Act. Reporte                  */
/*   30-Dic-2023      JANaguano        	   C00000368	                 */
/*************************************************************************/


-- exec sp_reporte_cuadro_sib  @i_operacion = 'G',@i_opcion = '1',@i_fecha = '03/31/2017'

-- SELECT * FROM cv_reporte_inventario_sib



use cob_coactiva
go
if not object_id('sp_reporte_cuadro_sib') is null
   drop procedure sp_reporte_cuadro_sib
go
create procedure sp_reporte_cuadro_sib
(      
   @i_operacion                     char(1) ,             --Operacion a Ejecutar   
   @i_opcion                        char(1)     = '',    --Opcion a ejecutar dentro de una operacion   
   @i_fecha                         datetime    = null,  --Fecha de proceso
   @i_oficina                       smallint    = null   --Oficina de generacion datos
 )
as
declare
   @w_sp_name                    varchar(32),  --nombre del stored procedure     
   @w_num_error                  int,          --numero de error  
   @w_commit                     char(1),      --flag para verificar si debe hacer commit tran
   @w_tabla_estado_juicio        int,          --Tabla catalogo de Estaos de Juicio
   
   -----------------------------------
   --Variables para manejo del reporte
   -----------------------------------
   @w_juicio_sec              int         ,     --Secuencial del juicio      
   @w_coactivado              varchar(200),     --Nombre del coactivado
   @w_conyuge                 varchar(100),     --Nombre del conyuge del coactivado   
   @w_operacion               varchar(24) ,    --Operacion coactivada
   @w_cuantia_inicial         money       ,     --Cuantia inicial del juicio
   @w_secretario              varchar(100),     --Nombre del secretario del juicio
   @w_fec_auto_pago           datetime    ,     --Fecha de auto de pago
   @w_linea                   tinyint     ,     --Numero de lina de la observacion
   @w_maximo                  tinyint     ,     --Maximo observaciones de un juicio   
   @w_linea_observa           varchar(1000),    --Observaciones del juicio por linea 1     
   @w_observacion             varchar(8000),    --Observaciones del juicio     
   @w_max_lin_observacion     tinyint,          --Máxima lineas de observacion a presentar
   @w_pos                     int,              --Contador de cadena   
   @w_contador                int,              --Contador para insertar secuencial en base a operaciones de juicio      
   @w_estado_archivado        varchar(10),      --Estado archivado del Juicio
   @w_estado_no_vigente       varchar(10),      --Estado no vigente del Juicio   
   @w_estado_anualdo          varchar(10),      --Estado anulado el Juicio      
   @w_mes_ejec                varchar(2),       --mes de fecha
   @w_anio_ejec               varchar(4),       --anio de fecha
   @w_dia_ejec                int,              --dia de fecha
   @w_dofi_procesa            varchar(64) ,     --Oficina Procesa
   @w_ofi_procesa             smallint,         --Codigo de oficina procesa
   @w_mes_fecha               varchar(10),      --mes de fecha procesa 
   @w_anio                    int,              --Anio del juicio   
   @w_num_juicio              varchar(24),      --Numero de juicio
   @w_etapa_procesal          varchar(64),      --Etapa procesal
   @w_fec_ult_providencia     datetime,         --Fecha ultima providencia
   @w_riesgo_actual           money,            --Riesgo actual  de la operacion 
   @w_garante                 varchar(350),     --Nombre de los garantes del juicio    
   @w_nombre                  varchar(100),     --Nombre de los garantes / representantes del juicio   
   @w_operacion_cod           int,              --Codigo de operacion   
   @w_fec_can_providencia     datetime,         --Fecha providencia cancelacion   
   @w_fec_arc_providencia     datetime,         --Fecha providencia archivo
   @w_bien_mueble             char(1),          --Parametro Bien Mueble
   @w_bien_inmueble           char(1),          --Parametro Bien Inmueble
   @w_tabla_bien_m            int,              --Codigo de Catalogo de tipo de bienes muebles
   @w_tabla_bien_i            int,              --Codigo de Catalogo de tipo de bienes inmuebles
   @w_fec_embargo             datetime,         --Fecha de Embargo del bien   
   @w_fec_insc_emb            datetime,         --Fecha de inscripcion del embargo   
   @w_tipo_bien               varchar(64),      --Tipo de Bien
   @w_desc_bien               varchar(500),     --Descripcion del Bien   
   @w_fec_insc_adj            datetime,         --Fecha de inscripcion de la adjudicacion
   @w_estado_eliminado        char(1),          --Codigo estado eliminado de embargos   
   @w_embargo_sec             int,              --Secuencial del embargo      
   @w_adjudicacion_sec        int,              --Secuencial de la adjudicacion
   @w_fecha_desde             datetime,         --Fecha desde
   @w_fecha_hasta             datetime,         --Fecha hasta   
   @w_tabla_fpago             int,              --Codigo de Catalogo de forma pago  
   @w_forma_pago              varchar(64),      --Forma Pago   
   @w_fecha_desde_tri         datetime,         --Fecha desde trimestral
   @w_quiebra_sec             int,              --Id de quiebra  
   @w_demandado_nom           varchar(150),     --nombre del demandado
   @w_ced_demandado           varchar(30),      --cedula del demandado   
   @w_cat_estado_procesal     int,              --Catalogo Estados del proceso   
   @w_obs_patrocinio          varchar(500),     --Observacion Patrocinio      
   @w_est_procesal            varchar(200),     --Estado Procesal
   @w_accion_sec              int,              --Id de quiebra     
   @w_num_juicio_ord             varchar(50),      --No Juicio Ordinario 
   @w_juzgado                    varchar(100),     --Nombre del juzgado
   @w_obs_coactiva            varchar(500),     --Observacion coactiva    
   @w_mes_fecha_desde         varchar(10),      --mes de fecha desde        
   @w_mes_fecha_desde_tri     varchar(10),      --mes de fecha desde trimestral   
   @w_mes                     int,              --mes de fecha   
   @w_cont                    int,              --contador   
   @w_ad1                     money,            --remate adjudicado mes 1      
   @w_ab1                     money,            --abono mes 1      
   @w_ad2                     money,            --remate adjudicado mes 2      
   @w_ab2                     money,            --abono mes 2      
   @w_ad3                     money,            --remate adjudicado mes 3      
   @w_ab3                     money,            --abono mes 3      
   @w_ad4                     money,            --remate adjudicado mes 4      
   @w_ab4                     money,            --abono mes 4      
   @w_ad5                     money,            --remate adjudicado mes 5      
   @w_ab5                     money,            --abono mes 5      
   @w_ad6                     money,            --remate adjudicado mes 6      
   @w_ab6                     money,            --abono mes 6      
   @w_ad7                     money,            --remate adjudicado mes 7      
   @w_ab7                     money,            --abono mes 7      
   @w_ad8                     money,            --remate adjudicado mes 8      
   @w_ab8                     money,            --abono mes 8      
   @w_ad9                     money,            --remate adjudicado mes 9      
   @w_ab9                     money,            --abono mes 9      
   @w_ad10                    money,            --remate adjudicado mes 10      
   @w_ab10                    money,            --abono mes 10      
   @w_ad11                    money,            --remate adjudicado mes 11      
   @w_ab11                    money,            --abono mes 11      
   @w_ad12                    money,            --remate adjudicado mes 12      
   @w_ab12                    money,            --abono mes 12         
   @w_user_batch              varchar(8),       --Usuario batch 
   @w_term_batch              varchar(9),       --Terminal bacth
   @w_fecha_ini               datetime,         --fecha inicio
   @w_fecha_fin               datetime,         --fecha fin
   @w_fecha_inicial           varchar(10),      --fecha inicial
   @w_fecha_final             varchar(10),      --fecha final 
   @w_remate_adjudicado       money,            --Valor de remate adjudicado
   @w_abono                   money,            --Valor de abono
   @w_oficina_batch           smallint,         --Oficina Batch
   @w_mes_tri_ini             int,              --mes inicio de trimestre      
   @w_fecha_fin3              datetime,         --fecha fin primer trimestre
   @w_fecha_fin6              datetime,         --fecha fin segundo trimestre
   @w_fecha_fin9              datetime,         --fecha inicio tercer trimestre
   @w_recau_efec              money,            --recaudacion efectivo     
   @w_recau_nova              money,            --recaudacion novacion    
   @w_estado_procesal         varchar(500),     --Estado procesal  
   @w_tabla_bien              int,              --Codigo de Catalogo de tipo de bienes   
   @w_usuario                 varchar(14),      --Usuario  
   @w_cant_obs                int,               --Cantidad de observaciones                
   @w_estado_preliminar        varchar(10)		--CAMBIO

--------------------------------------
--Inicializacion de Variables
--------------------------------------
select @w_commit              = 'N',
       @w_max_lin_observacion =  5,
       @w_estado_eliminado    = 'E',
       @w_sp_name             = 'sp_reporte_cuadro_sib',
       @w_user_batch          = 'batchsif',
       @w_term_batch          = 'TERMSIF'  
select  @w_estado_preliminar = 'P'	--C00000368      
select @w_oficina_batch = pa_smallint 
from cobis..cl_parametro
where pa_nemonico = 'OFEB'
and   pa_producto = 'COA'                     

select @w_tabla_estado_juicio = codigo
from cobis..cl_tabla
where tabla  = 'cv_estado_juicio'  

select  @w_estado_archivado = codigo 
from cobis..cl_catalogo 
where tabla = @w_tabla_estado_juicio
and   valor = 'ARCHIVADO'


select  @w_estado_anualdo = codigo 
from cobis..cl_catalogo 
where tabla = @w_tabla_estado_juicio
and   valor = 'ANULADO'

select  @w_estado_no_vigente = codigo 
from cobis..cl_catalogo 
where tabla = @w_tabla_estado_juicio
and   valor = 'NO VIGENTE'

select @w_oficina_batch = pa_smallint 
from cobis..cl_parametro
where pa_nemonico = 'OFEB'
and pa_producto = 'COA'

select @w_tabla_bien = codigo
from cobis..cl_tabla 
where tabla = 'cv_clase_bien'

if @i_oficina = 0
   select @i_oficina = null
   
if @i_operacion = 'G' and @i_opcion = '2'
begin
   select @w_tabla_fpago = codigo
   from cobis..cl_tabla 
   where tabla = 'cv_pago_archivo'
   if @@rowcount = 0
   begin
      select @w_num_error = 760016
      goto errores
   end
end   

---Estado Procesal
select @w_cat_estado_procesal = codigo 
from cobis..cl_tabla 
where tabla = 'cv_quiebra_insolv_est_procesal'

if @@rowcount = 0
begin
   select @w_num_error = 760293 --No existe Parametrizacion Base - Catalogo cv_quiebra_insolv_est_procesal
   goto errores
end    


if @i_operacion = 'G' and @i_opcion = '3'
begin
   select @w_bien_mueble = pa_char
   from cobis..cl_parametro 
   where pa_producto = 'COA'
   and   pa_nemonico = 'CBMUE'   
   if @@rowcount = 0 
   begin
      select @w_num_error = 760012 --No existe parametro
      goto errores
   end   
   
   select @w_bien_inmueble = pa_char
   from cobis..cl_parametro 
   where pa_producto = 'COA'
   and   pa_nemonico = 'CBINM'   
   if @@rowcount = 0
   begin
      select @w_num_error = 760012 --No existe parametro
      goto errores
   end
   
   select @w_tabla_bien_m = codigo
   from cobis..cl_tabla 
   where tabla = 'cv_tipo_bien_mueble'
   if @@rowcount = 0
   begin
      select @w_num_error = 760016
      goto errores
   end
   
   select @w_tabla_bien_i = codigo
   from cobis..cl_tabla 
   where tabla = 'cv_tipo_bien_inmueble'
   if @@rowcount = 0
   begin
      select @w_num_error = 760016
      goto errores
   end
end 
   
--Obtener fecha desde y hasta
select @w_mes_ejec  = str(datepart(mm,dateadd(mm,-2,@i_fecha)),2),
       @w_anio_ejec = str(datepart (yy, @i_fecha),4)
select @w_fecha_desde     = convert(datetime, ('01/01/'+@w_anio_ejec),101),
       @w_fecha_hasta     = @i_fecha,
       @w_fecha_desde_tri = convert(datetime, (@w_mes_ejec+'/01/'+@w_anio_ejec),101) 
       
-- EC 05/06/2017 Agrupacion de datos por Riesgo Actual
      
CREATE TABLE #cv_reporte_inventario_sib
		(
			is_fecha_proceso       DATETIME NOT NULL,
			is_secuencial          INT IDENTITY ,
			is_secuencia_ju        INT NULL,
			is_num_juicio          VARCHAR (8) NULL,
			is_anio                INT NULL,
			is_coactivado          VARCHAR (200) NULL,
			is_garante             VARCHAR (350) NULL,
			is_fec_auto_pago       DATETIME NULL,
			is_cuantia_inicial     MONEY NULL,
			is_riesgo_actual       MONEY NULL,
			is_etapa_procesa       VARCHAR (64) NULL,
			is_fec_ult_providencia DATETIME NULL,
			is_observacion         TEXT NULL,
			is_abogado             VARCHAR (100) NULL,
			is_oficina_procesa     SMALLINT NULL,
			is_doficina_procesa    VARCHAR (64) NULL
		)
                                   
------------------------
-- Generacion de datos --
-------------------------
if @i_operacion = 'G'
begin
   if @i_opcion = '1'
   begin         
      delete cv_reporte_inventario_sib
      
      select @w_cuantia_inicial  = null,
             @w_contador         = 0   
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,       substring(j.ju_juicio,6,4),     convert(int,substring(j.ju_juicio,1,4)),      isnull(f.en_nomlar, f.en_nombre),  
                j.ju_fecha_auto_pago,        j.ju_monto_inicial_juicio,    o.jo_operacion_asiento,                       p.pe_nombre,
                j.ju_fecha_ult_providencia,  r.re_nombre,                  j.ju_oficina_procesa,                         d.of_nombre    
      from cv_juicio j, cobis..cl_ente f,cv_responsables r,cobis..cl_oficina d,cv_param_etapas p,cv_juicio_operacion o 
      where f.en_ente              =* j.ju_ente_deudor
      and   r.re_codigo            =* j.ju_cod_secretario
      and   p.pe_cod_etapa         = j.ju_etapa
      and   o.jo_juicio_sec        = j.ju_juicio_sec      
      and   j.ju_oficina_procesa   =  d.of_oficina
      and   j.ju_estado not in (@w_estado_archivado, @w_estado_no_vigente, @w_estado_anualdo, @w_estado_preliminar)    --C00000368
      order by j.ju_fecha_auto_pago,convert(int,substring(j.ju_juicio,1,4)),substring(j.ju_juicio,6,4)
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_anio,                 @w_coactivado,
                             @w_fec_auto_pago,         @w_cuantia_inicial,    @w_operacion,            @w_etapa_procesal,
                             @w_fec_ult_providencia,   @w_secretario,         @w_ofi_procesa,          @w_dofi_procesa
                                     
      While @@sqlstatus != 2
      begin           
                         
         select @w_contador    = @w_contador + 1   
         select @w_garante     = ""        
        
         --Obtener el conyugue del coactivado si existe
         select @w_conyuge = "" 
         
         select @w_conyuge     = isnull(en_nomlar, en_nombre)
         from  cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'Y'  --Conyugue
         and   en_ente       = jd_ente_deudor 
                      
         if @w_conyuge != "" and @w_conyuge is not null
         begin                  
            select @w_pos = 0   
            select @w_pos = CHARINDEX(@w_conyuge, @w_coactivado)            
            if @w_pos = 0 and ltrim(rtrim(@w_conyuge)) != '' and @w_conyuge is not null
            begin
               if  @w_coactivado  = ''
                  select @w_coactivado = @w_conyuge                  
               else                  
                  select @w_coactivado = @w_coactivado + " / " + @w_conyuge                  
            end               
         end
         
         --Obtener Garantes
         declare cur_garantes cursor for
         select isnull(en_nomlar, en_nombre)
         from cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'G'  --Garantes
         and   en_ente       = jd_ente_deudor 
                
         Open cur_garantes
         Fetch  cur_garantes into @w_nombre
         While @@sqlstatus != 2
         begin 
            if @w_nombre != null or @w_nombre != ""
            begin                      
               select @w_pos = 0
               select @w_pos = CHARINDEX(@w_nombre, @w_garante)
               if @w_pos = 0 and ltrim(rtrim(@w_nombre)) != '' and @w_nombre is not null
               if @w_garante = ''
                  select @w_garante = @w_nombre   
               else
                  select @w_garante = @w_garante + " / " + @w_nombre   
            end
            Fetch  cur_garantes into @w_nombre
         end        
         close cur_garantes
         deallocate cursor cur_garantes         
         
         --Riesgo actual de la operacion
         select @w_operacion_cod  = null
         
            select @w_operacion_cod = op_operacion
           from cob_cartera..ca_operacion
           where op_banco = @w_operacion
            
           select @w_riesgo_actual = null
                      
           select @w_riesgo_actual = (  select sum(am_acumulado + am_gracia - am_pagado - am_exponencial)
                                        from   cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                                        where  di_operacion  = @w_operacion_cod
                                        and    ro_operacion  = @w_operacion_cod
                                        and    am_operacion  = @w_operacion_cod
                                        and    di_operacion  = ro_operacion 
                                        and    di_estado     not in (3)
                                        and    ro_operacion  = am_operacion
                                        and    ro_concepto   = am_concepto
                                        and    am_dividendo  = di_dividendo)         
         
         --Tomar Observaciones del juicio
         select @w_linea = 1 ,
                @w_observacion = ''
         
         select @w_maximo = max(jo_num_observacion)
         from cv_juicio_observaciones
         where jo_juicio_sec = @w_juicio_sec
         
         if @w_maximo > @w_max_lin_observacion
            select @w_linea = (@w_maximo - @w_max_lin_observacion) + 1
         
         while @w_linea <= @w_maximo
         begin
            select @w_linea_observa = jo_observacion
            from cv_juicio_observaciones
            where jo_juicio_sec = @w_juicio_sec
            and jo_num_observacion = @w_linea 
                          
            select @w_observacion  = @w_observacion + ' ' + @w_linea_observa                                       
            select @w_linea = @w_linea + 1               
         end
               
         select @w_observacion = LTRIM(RTRIM(@w_observacion))                

            
           --Inserto Datos                          
          insert cv_reporte_inventario_sib 
                 (   is_fecha_proceso,          is_secuencial,       is_secuencia_ju,       is_num_juicio,
                    is_anio,                   is_coactivado,       is_garante,              is_fec_auto_pago,   
                    is_cuantia_inicial,        is_riesgo_actual,    is_etapa_procesa,      is_fec_ult_providencia,    
                    is_observacion,            is_abogado,          is_oficina_procesa,    is_doficina_procesa)                 
         values (   @i_fecha,                  @w_contador,         @w_juicio_sec,         @w_num_juicio,
                    @w_anio,                   @w_coactivado,       @w_garante,            @w_fec_auto_pago,
                    @w_cuantia_inicial,        @w_riesgo_actual,    @w_etapa_procesal,     @w_fec_ult_providencia,
                    @w_observacion,            @w_secretario,       @w_ofi_procesa,        @w_dofi_procesa)
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end   
          
         --Encerar Variables  
           select @w_coactivado        = null,   @w_cuantia_inicial   = null,   @w_observacion       = null, @w_conyuge            = null                                    
                                    
             Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_anio,                 @w_coactivado,
                                   @w_fec_auto_pago,         @w_cuantia_inicial,    @w_operacion,            @w_etapa_procesal,
                                   @w_fec_ult_providencia,   @w_secretario,         @w_ofi_procesa,          @w_dofi_procesa                                    
         end
         Close cur_juicio
         Deallocate cursor cur_juicio  
         
         
         -- EC 05/06/2017 Agrupacion de datos por Riesgo Actual
         
         	
		INSERT #cv_reporte_inventario_sib
		SELECT 
			is_fecha_proceso ,
			is_secuencia_ju ,
			is_num_juicio ,
			is_anio    ,
			is_coactivado ,
			is_garante    ,
			is_fec_auto_pago  ,
			is_cuantia_inicial,
			SUM(is_riesgo_actual ) ,
			is_etapa_procesa  ,
			is_fec_ult_providencia ,
			'' is_observacion  ,
			is_abogado       ,
			is_oficina_procesa   ,
			is_doficina_procesa    
		FROM cv_reporte_inventario_sib
		--WHERE is_num_juicio LIKE '%0151%'
		
		GROUP BY is_fecha_proceso ,	
		is_secuencia_ju ,	is_num_juicio ,	is_anio    ,	is_coactivado ,	is_garante    ,	is_fec_auto_pago  ,
			is_cuantia_inicial,--is_riesgo_actual  ,    
				is_etapa_procesa  ,	is_fec_ult_providencia ,	--is_observacion  ,
			is_abogado       ,	is_oficina_procesa   ,	is_doficina_procesa  
		ORDER BY is_fec_auto_pago ,is_secuencia_ju
			

		-- OBSERVACION
		
		--SELECT t1.is_secuencia_ju ,t1.is_num_juicio, t1.is_observacion  ,t2.is_observacion  
		UPDATE #cv_reporte_inventario_sib SET is_observacion = t1.is_observacion 
		FROM cv_reporte_inventario_sib t1 ,#cv_reporte_inventario_sib t2
		WHERE --t1.is_num_juicio LIKE '%0151%' and
		t1.is_secuencia_ju = t2.is_secuencia_ju
		AND t1.is_num_juicio = t2.is_num_juicio 		
		
		-- DROP TABLE #cv_reporte_inventario_sib

		DELETE FROM cv_reporte_inventario_sib
		
		INSERT  cv_reporte_inventario_sib
		SELECT * FROM #cv_reporte_inventario_sib
         
         -- EC Fin cambio
         
         
         
   end   
   
   if @i_opcion = '2' --Archivados
   begin   
      delete cv_reporte_archivado_sib
                         
      select @w_cuantia_inicial  = null,
             @w_contador         = 0   
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,              substring(ju_juicio,6,4),     convert(int,substring(j.ju_juicio,1,4)),      isnull(f.en_nomlar, f.en_nombre),  
                j.ju_monto_inicial_juicio,    j.ju_oficina_procesa,         d.of_nombre,                                  j.ju_fecha_ult_providencia,
                j.ju_fecha_ult_providencia,   (select Z.valor from cobis..cl_catalogo Z where  Z.tabla = @w_tabla_fpago and Z.codigo = j.ju_forma_pago )               
      from cv_juicio j, cobis..cl_ente f, cobis..cl_oficina d
      where f.en_ente                     =* j.ju_ente_deudor
      and   j.ju_oficina_procesa          =  d.of_oficina
      and   j.ju_estado                   = @w_estado_archivado 
      and   convert (char(10),j.ju_fecha_ult_providencia ,112) >= @w_fecha_desde_tri and convert (char(10),j.ju_fecha_ult_providencia,112) <= @w_fecha_hasta            
      order by j.ju_fecha_ult_providencia,convert(int,substring(j.ju_juicio,1,4)),substring(j.ju_juicio,6,4)
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_anio,                 @w_coactivado,
                             @w_cuantia_inicial,       @w_ofi_procesa,        @w_dofi_procesa,         @w_fec_can_providencia,
                               @w_fec_arc_providencia,   @w_forma_pago           
                                     
      While @@sqlstatus != 2
      begin 
         select @w_contador    = @w_contador + 1          
        
         --Obtener el conyugue del coactivado si existe
         select @w_conyuge = "" 
         
         select @w_conyuge     = isnull(en_nomlar, en_nombre)
         from  cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'Y'  --Conyugue
         and   en_ente       = jd_ente_deudor 
                      
         if @w_conyuge != "" and @w_conyuge is not null
         begin                  
            select @w_pos = 0   
            select @w_pos = CHARINDEX(@w_conyuge, @w_coactivado)            
            if @w_pos = 0 and ltrim(rtrim(@w_conyuge)) != '' and @w_conyuge is not null
            begin
               if  @w_coactivado  = ''
                  select @w_coactivado = @w_conyuge                  
               else                  
                  select @w_coactivado = @w_coactivado + " / " + @w_conyuge                  
            end               
         end            
         
         --Riesgo actual de la operacion       
         select @w_riesgo_actual = 0         
                         
         declare cur_operaciones cursor for
         select jo_operacion_asiento
         from cv_juicio_operacion
         where jo_juicio_sec = @w_juicio_sec         
                
         Open cur_operaciones
         Fetch  cur_operaciones into @w_operacion
         While @@sqlstatus != 2
         begin 
            select @w_operacion_cod  = null
            
               select @w_operacion_cod = op_operacion
              from cob_cartera..ca_operacion
              where op_banco = @w_operacion              
            
                         
              select @w_riesgo_actual = @w_riesgo_actual + (  select sum(am_acumulado + am_gracia - am_pagado - am_exponencial)
                                                              from   cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                                                                where  di_operacion  = @w_operacion_cod
                                                              and    ro_operacion  = @w_operacion_cod
                                                              and    am_operacion  = @w_operacion_cod
                                                              and    di_operacion  = ro_operacion 
                                                              and    di_estado     not in (3)
                                                              and    ro_operacion  = am_operacion
                                                              and    ro_concepto   = am_concepto
                                                              and    am_dividendo  = di_dividendo)      
            Fetch  cur_operaciones into @w_operacion
         end
         
         close cur_operaciones
         deallocate cursor cur_operaciones    
            
           --Inserto Datos                          
          insert cv_reporte_archivado_sib 
                 (   as_fecha_proceso,         as_secuencial,                as_secuencia_ju,      as_num_juicio,
                    as_anio,                   as_coactivado,                as_cuantia_inicial,   as_riesgo_actual,
                    as_fec_can_providencia,    as_fec_arc_providencia,       as_oficina_procesa,   as_doficina_procesa,
                    as_forma_pago)                 
         values (   @i_fecha,                  @w_contador,                  @w_juicio_sec,        @w_num_juicio,
                    @w_anio,                   @w_coactivado,                @w_cuantia_inicial,   @w_riesgo_actual,
                    @w_fec_can_providencia,    @w_fec_arc_providencia,       @w_ofi_procesa,       @w_dofi_procesa,
                    @w_forma_pago)
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end   
          
         --Encerar Variables  
           select @w_coactivado        = null,   @w_cuantia_inicial   = null,     @w_conyuge            = null                                    
                                    
          Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_anio,                 @w_coactivado,
                                @w_cuantia_inicial,       @w_ofi_procesa,        @w_dofi_procesa,         @w_fec_can_providencia,
                                @w_fec_arc_providencia,   @w_forma_pago           
         end
         Close cur_juicio
         Deallocate cursor cur_juicio           
   end   

   if @i_opcion = '3' --Embargos
   begin   
         
      delete cv_reporte_embargo_sib  
      
      select @w_contador = 0   
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,              ju_juicio,                    isnull(f.en_nomlar, f.en_nombre),     e.ee_fecha_embargo,  
                e.ee_fecha_inscripcion,       j.ju_oficina_procesa,         d.of_nombre,                          e.ee_id_embargo, 
                a.valor,                      e.ee_observacion                      
      from cv_juicio j, cobis..cl_ente f, cobis..cl_oficina d,cv_etapa_embargo e,cv_juicio_bienes z,cobis..cl_catalogo a
      where f.en_ente              =* j.ju_ente_deudor
      and   j.ju_oficina_procesa   =  d.of_oficina
      and   e.ee_juicio_sec        =  j.ju_juicio_sec   
      and   e.ee_secuencial_bien   =  z.jb_secuencial_bien  
      and   e.ee_estado not in (@w_estado_eliminado)  
      and   convert (char(10),e.ee_fecha_embargo,112) >= @w_fecha_desde and convert (char(10),e.ee_fecha_embargo,112) <= @w_fecha_hasta                        
      and   a.tabla = @w_tabla_bien
      and   a.codigo = z.jb_clase_bien
      and   (convert (char(10),e.ee_fecha_inscripcion,112) <= @w_fecha_hasta or ee_fecha_inscripcion is null)                                       
      order by e.ee_fecha_embargo
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_coactivado,        @w_fec_embargo,
                             @w_fec_insc_emb,          @w_ofi_procesa,        @w_dofi_procesa,      @w_embargo_sec,
                             @w_tipo_bien,             @w_observacion
                                     
      While @@sqlstatus != 2
      begin 
         select @w_contador = @w_contador + 1   
         
         --Obtener el conyugue del coactivado si existe
         select @w_conyuge = "" 
         
         select @w_conyuge     = isnull(en_nomlar, en_nombre)
         from  cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'Y'  --Conyugue
         and   en_ente       = jd_ente_deudor 
                      
         if @w_conyuge != "" and @w_conyuge is not null
         begin                  
            select @w_pos = 0   
            select @w_pos = CHARINDEX(@w_conyuge, @w_coactivado)            
            if @w_pos = 0 and ltrim(rtrim(@w_conyuge)) != '' and @w_conyuge is not null
            begin
               if  @w_coactivado  = ''
                  select @w_coactivado = @w_conyuge                  
               else                  
                  select @w_coactivado = @w_coactivado + " / " + @w_conyuge                  
            end               
         end                     
                        
         select @w_observacion = LTRIM(RTRIM(@w_observacion))              
            
           --Inserto Datos                          
          insert cv_reporte_embargo_sib 
                 (  es_fecha_proceso,          es_secuencial,                es_secuencia_ju,      es_num_juicio,   
                    es_coactivado,             es_fec_embargo,               es_tipo_bien,         es_fec_embargo_ins,
                    es_observacion,            es_oficina_procesa,           es_doficina_procesa,  es_secuencial_emb)
         values (   @i_fecha,                  @w_contador,                  @w_juicio_sec,        @w_num_juicio,
                    @w_coactivado,             @w_fec_embargo,               @w_tipo_bien,         @w_fec_insc_emb,
                    @w_observacion,            @w_ofi_procesa,               @w_dofi_procesa,      @w_embargo_sec)
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end   
          
         --Encerar Variables  
           select @w_coactivado = null,   @w_conyuge    = null
          Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_coactivado,        @w_fec_embargo,
                                @w_fec_insc_emb,          @w_ofi_procesa,        @w_dofi_procesa,      @w_embargo_sec,
                                @w_tipo_bien,             @w_observacion
         end
         Close cur_juicio
         Deallocate cursor cur_juicio              
   end   

   if @i_opcion = '4' --Adjudicaciones
   begin   
      delete cv_reporte_adjudicacion_sib  
         
      select @w_contador = 0   
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,              ju_juicio,                    isnull(f.en_nomlar, f.en_nombre),     z.jb_desc_resumen,  
                e.ab_fecha_inscripcion,       j.ju_oficina_procesa,         d.of_nombre,                          e.ab_secuencial_adjudicacion
      from cv_juicio j, cobis..cl_ente f, cobis..cl_oficina d,cv_adjudicacion_bien e,cv_juicio_bienes z
      where f.en_ente              =* j.ju_ente_deudor
      and   j.ju_oficina_procesa   =  d.of_oficina
      and   z.jb_juicio_sec        =  j.ju_juicio_sec   
      and   e.ab_secuencial_bien   =  z.jb_secuencial_bien
      and   e.ab_estado        not in (@w_estado_eliminado)  
      and   convert (char(10),e.ab_fecha_auto_adjudicacion,112) >= @w_fecha_desde and convert (char(10),e.ab_fecha_auto_adjudicacion,112) <= @w_fecha_hasta                                  
      order by e.ab_fecha_auto_adjudicacion
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_coactivado,        @w_desc_bien,
                             @w_fec_insc_adj,          @w_ofi_procesa,        @w_dofi_procesa,         @w_adjudicacion_sec 
                                     
      While @@sqlstatus != 2
      begin 
         select @w_contador    = @w_contador + 1   
         
         --Obtener el conyugue del coactivado si existe
         select @w_conyuge = "" 
         
         select @w_conyuge     = isnull(en_nomlar, en_nombre)
         from  cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'Y'  --Conyugue
         and   en_ente       = jd_ente_deudor 
                      
         if @w_conyuge != "" and @w_conyuge is not null
         begin                  
            select @w_pos = 0   
            select @w_pos = CHARINDEX(@w_conyuge, @w_coactivado)            
            if @w_pos = 0 and ltrim(rtrim(@w_conyuge)) != '' and @w_conyuge is not null
            begin
               if  @w_coactivado  = ''
                  select @w_coactivado = @w_conyuge                  
               else                  
                  select @w_coactivado = @w_coactivado + " / " + @w_conyuge                  
            end               
         end                              
            
           --Inserto Datos                          
          insert cv_reporte_adjudicacion_sib 
                 (   as_fecha_proceso,          as_secuencial,               as_secuencia_ju,      as_secuencia_adj, 
                    as_num_juicio,             as_coactivado,                as_desc_bien,         as_fec_isncripcion,    
                    as_oficina_procesa,        as_doficina_procesa )
         values (   @i_fecha,                  @w_contador,                  @w_juicio_sec,        @w_adjudicacion_sec,
                    @w_num_juicio,             @w_coactivado,                @w_desc_bien,         @w_fec_insc_adj,
                    @w_ofi_procesa,            @w_dofi_procesa)
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end   
          
         --Encerar Variables  
           select @w_coactivado = null,   @w_conyuge    = null
          Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_coactivado,        @w_desc_bien,
                                @w_fec_insc_adj,          @w_ofi_procesa,        @w_dofi_procesa,      @w_adjudicacion_sec
         end
         Close cur_juicio
         Deallocate cursor cur_juicio   
   end   

   if @i_opcion = '5' --Excepciones
   begin   
      delete cv_reporte_excepcion_sib  
         
      select @w_cuantia_inicial  = null,
             @w_contador         = 0
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,              j.ju_juicio,    a.ac_sec_acciones_coactivado,        j.ju_monto_inicial_juicio,
                a.ac_numero_juicio_ordinario, a.ac_juzgado,   j.ju_fecha_ult_providencia,          j.ju_oficina_procesa,
                d.of_nombre,                  a.ac_observacion_coactiva  
      from cv_acciones_coactivado a
      join cv_juicio j on (a.ac_juicio_sec = j.ju_juicio_sec)
      join cobis..cl_oficina d on (j.ju_oficina_procesa = d.of_oficina)
      where a.ac_estado            = 'V' 
      and   a.ac_accion_coactivado = 'JE'     
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_accion_sec,          @w_cuantia_inicial,
                             @w_num_juicio_ord,        @w_juzgado,            @w_fec_ult_providencia, @w_ofi_procesa,
                             @w_dofi_procesa,          @w_obs_coactiva
                                     
      While @@sqlstatus != 2
      begin 
         select @w_contador    = @w_contador + 1,            
                @w_observacion      = ""   
        
         --Obtener Observacion
         declare cur_estado cursor for
         select a.op_observacion_patrocinio,
               (select b.valor from cobis..cl_catalogo b where b.tabla = @w_cat_estado_procesal and b.codigo = a.op_estado_procesal),
               a.op_txt_estado,
               a.op_fecha_ult_providencia
         from cv_observaciones_patrocinio a
         where a.op_causa = 'AC'
         and a.op_sec_relacionada = @w_accion_sec
         and a.op_estado          = 'V'         
                
         Open cur_estado
         Fetch  cur_estado into @w_obs_patrocinio, @w_nombre, @w_estado_procesal, @w_fec_ult_providencia
         While @@sqlstatus != 2
         begin                         
            if @w_obs_patrocinio != null or @w_obs_patrocinio != ""
            begin                      
               select @w_pos = 0
               select @w_pos = CHARINDEX(@w_obs_patrocinio, @w_observacion)
               if @w_pos = 0 and ltrim(rtrim(@w_obs_patrocinio)) != '' and @w_obs_patrocinio is not null
               if @w_observacion = ''
                  select @w_observacion = @w_obs_patrocinio   
               else
                  select @w_observacion = @w_observacion + " / " + @w_obs_patrocinio   
            end            
            
            Fetch  cur_estado into @w_obs_patrocinio, @w_nombre, @w_estado_procesal, @w_fec_ult_providencia
         end        
         close cur_estado
         deallocate cursor cur_estado                                              
            
           --Inserto Datos                          
          insert cv_reporte_excepcion_sib 
                 (   es_fecha_proceso,          es_secuencial,                es_secuencia_ju,            es_num_juicio,    
                    es_cuantia_inicial,        es_num_juicio_exc,            es_juzgado,                   es_estado_procesal, 
                    es_fec_ult_providencia,    es_observacion,               es_oficina_procesa,         es_doficina_procesa,
                    es_accion_sec )                 
         values (   @i_fecha,                  @w_contador,                  @w_juicio_sec,              @w_num_juicio,
                    @w_cuantia_inicial,        @w_num_juicio_ord,            @w_juzgado,                 @w_estado_procesal,
                    @w_fec_ult_providencia,    @w_observacion,               @w_ofi_procesa,             @w_dofi_procesa,
                    @w_accion_sec)
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end   
          
         --Encerar Variables  
           select @w_observacion  = null, @w_obs_patrocinio = null
            Fetch cur_juicio into @w_juicio_sec,          @w_num_juicio,         @w_accion_sec,          @w_cuantia_inicial,
                                @w_num_juicio_ord,        @w_juzgado,            @w_fec_ult_providencia, @w_ofi_procesa,
                                @w_dofi_procesa,          @w_obs_coactiva
         end
         Close cur_juicio
         Deallocate cursor cur_juicio           
   end 

   if @i_opcion = '6' --Insolvencias
   begin   
      delete cv_reporte_insolvencia_sib  
         
      select @w_cuantia_inicial  = null,
             @w_contador         = 0
             
      --Genero datos del reporte      
       Declare  cur_juicio  cursor for
       select   j.ju_juicio_sec,              ju_juicio,      a.qi_sec_quiebra_insolvencia,        j.ju_fecha_ult_providencia,      
                j.ju_oficina_procesa,         d.of_nombre,    isnull(f.en_nomlar, f.en_nombre),    y.jd_ced_ruc,
                a.qi_usuario_crea
      from cv_quiebra_insolvencia a
      join cv_juicio j on (a.qi_juicio_sec = j.ju_juicio_sec)
      join cv_juicio_deudores y on (j.ju_juicio_sec = y.jd_juicio_sec)
      join cobis..cl_ente f on (f.en_ente = y.jd_ente_deudor)
      join cobis..cl_oficina d on (j.ju_oficina_procesa = d.of_oficina)
      where a.qi_estado = 'V'      
      
      Open cur_juicio 
       Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_quiebra_sec,        @w_fec_ult_providencia,
                             @w_ofi_procesa,           @w_dofi_procesa,       @w_demandado_nom,      @w_ced_demandado,
                             @w_usuario 
                                     
      While @@sqlstatus != 2
      begin 
         select @w_contador    = @w_contador + 1,
                @w_est_procesal     = "",          
                @w_observacion      = "",   
                @w_cant_obs         =0
                
         --Obtener Estado del Proceso y observacion
         declare cur_estado cursor for
         select a.op_observacion_patrocinio,
               (select b.valor from cobis..cl_catalogo b where b.tabla = @w_cat_estado_procesal and b.codigo = a.op_estado_procesal),
                a.op_fecha_ult_providencia 
         from cv_observaciones_patrocinio a
         where a.op_causa = 'QI'
         and a.op_sec_relacionada = @w_quiebra_sec
         and a.op_id_coactivado   = @w_ced_demandado
         and a.op_estado          = 'V'         
                
         Open cur_estado
         Fetch  cur_estado into @w_obs_patrocinio, @w_nombre, @w_fec_ult_providencia
         While @@sqlstatus != 2
         begin             
            select @w_cant_obs = @w_cant_obs + 1
            --Estado Proceso
            if @w_nombre != null or @w_nombre != ""
            begin                      
               select @w_pos = 0
               select @w_pos = CHARINDEX(@w_nombre, @w_est_procesal)
               if @w_pos = 0 and ltrim(rtrim(@w_nombre)) != '' and @w_nombre is not null
               if @w_est_procesal = ''
                  select @w_est_procesal = @w_nombre   
               else
                  select @w_est_procesal = @w_est_procesal + " / " + @w_nombre   
            end
              --Observacion
            if @w_obs_patrocinio != null or @w_obs_patrocinio != ""
            begin                      
               select @w_pos = 0
               select @w_pos = CHARINDEX(@w_obs_patrocinio, @w_observacion)
               if @w_pos = 0 and ltrim(rtrim(@w_obs_patrocinio)) != '' and @w_obs_patrocinio is not null
               if @w_observacion = ''
                  select @w_observacion = @w_obs_patrocinio   
               else
                  select @w_observacion = @w_observacion + " / " + @w_obs_patrocinio   
            end
            
            Fetch  cur_estado into @w_obs_patrocinio, @w_nombre, @w_fec_ult_providencia
         end        
         close cur_estado
         deallocate cursor cur_estado                                              
            
          if @w_cant_obs > 0
          begin
             --Inserto Datos                          
             insert cv_reporte_insolvencia_sib 
                    (   is_fecha_proceso,          is_secuencial,               is_secuencia_ju,            is_quiebra_sec,    
                       is_demandado,              is_estado_pro,                is_fec_ult_providencia,     is_observacion, 
                       is_oficina_procesa,        is_doficina_procesa,          is_num_juicio,              is_juez,
                       is_usuario )
            values (   @i_fecha,                  @w_contador,                  @w_juicio_sec,              @w_quiebra_sec,
                       @w_demandado_nom,          @w_est_procesal,              @w_fec_ult_providencia,     @w_observacion,
                       @w_ofi_procesa,            @w_dofi_procesa,              @w_num_juicio,              null,
                       @w_usuario)
                  
             if @@error != 0
             begin
                select @w_num_error = 760145  --Error en la generacion de reporte
                goto errores                  
             end   
          end
          
         --Encerar Variables  
           select @w_demandado_nom  = null,   @w_observacion  = null,   @w_nombre = null, 
                  @w_obs_patrocinio = null,   @w_est_procesal = null
          Fetch cur_juicio into @w_juicio_sec,            @w_num_juicio,         @w_quiebra_sec,        @w_fec_ult_providencia,
                                @w_ofi_procesa,           @w_dofi_procesa,       @w_demandado_nom,      @w_ced_demandado,
                                @w_usuario  
         end
         Close cur_juicio
         Deallocate cursor cur_juicio           
   end 

   if @i_opcion = '7' --Recuperaciones
   begin   
      delete cv_reporte_recuperacion_sib  
      where rs_fecha_proceso = @i_fecha
         
      select @w_cuantia_inicial  = null,
             @w_contador         = 0
      
      select @w_mes          = datepart(mm,@i_fecha),
             @w_mes_tri_ini  = datepart(mm,@w_fecha_desde_tri),
             @w_anio_ejec    = str(datepart (yy, @i_fecha),4)   
       
      --fecha fin de mes de 1er trimestre 
      select @w_mes_ejec  = '03'
      select @w_dia_ejec = day(dateadd(dd,-1,dateadd(dd,(day(@w_mes_ejec + '/01/' + @w_anio_ejec)-1)*-1,dateadd(mm,1, @w_mes_ejec + '/01/' + @w_anio_ejec))))                            
      select @w_fecha_fin3 = convert(datetime, (@w_mes_ejec +'/'+ str(@w_dia_ejec,2) +'/'+@w_anio_ejec),101)                                                 

      --fecha fin de mes de 2do trimestre 
      select @w_mes_ejec  = '06'
      select @w_dia_ejec = day(dateadd(dd,-1,dateadd(dd,(day(@w_mes_ejec + '/01/' + @w_anio_ejec)-1)*-1,dateadd(mm,1, @w_mes_ejec + '/01/' + @w_anio_ejec))))                            
      select @w_fecha_fin6 = convert(datetime, (@w_mes_ejec +'/'+ str(@w_dia_ejec,2) +'/'+@w_anio_ejec),101)                                                              


      --fecha fin de mes de 3er trimestre 
      select @w_mes_ejec  = '09'
      select @w_dia_ejec = day(dateadd(dd,-1,dateadd(dd,(day(@w_mes_ejec + '/01/' + @w_anio_ejec)-1)*-1,dateadd(mm,1, @w_mes_ejec + '/01/' + @w_anio_ejec))))                            
      select @w_fecha_fin9 = convert(datetime, (@w_mes_ejec +'/'+ str(@w_dia_ejec,2) +'/'+@w_anio_ejec),101)                                                                                                   

      declare cursor_oficinas cursor for
      select distinct
             j.ju_oficina_procesa,
             d.of_nombre
      from cv_juicio j,cobis..cl_oficina d
      where j.ju_oficina_procesa   =  d.of_oficina
      
      open cursor_oficinas
      
      fetch cursor_oficinas into @w_ofi_procesa, @w_dofi_procesa
      
      while (@@sqlstatus = 0)
      begin
         select @w_contador = @w_contador + 1
                
         if @w_mes > 3
         begin    
            select @w_ad1   = rs_ad1,
                   @w_ab1   = rs_ab1,
                   @w_ad2   = rs_ad2,
                   @w_ab2   = rs_ab2,                
                   @w_ad3   = rs_ad3,
                   @w_ab3   = rs_ab3                                
            from cv_reporte_recuperacion_sib
            where rs_fecha_proceso   = @w_fecha_fin3
            and   rs_oficina_procesa = @w_ofi_procesa                
         end   

         if @w_mes > 6
         begin    
            select @w_ad4   = rs_ad4,
                   @w_ab4   = rs_ab4,
                   @w_ad5   = rs_ad5,
                   @w_ab5   = rs_ab5,                
                   @w_ad6   = rs_ad6,
                   @w_ab6   = rs_ab6                                
            from cv_reporte_recuperacion_sib
            where rs_fecha_proceso   = @w_fecha_fin6
            and   rs_oficina_procesa = @w_ofi_procesa                
         end   
                
         if @w_mes > 9
         begin    
            select @w_ad7   = rs_ad7,
                   @w_ab7   = rs_ab7,
                   @w_ad8   = rs_ad8,
                   @w_ab8   = rs_ab8,
                   @w_ad9   = rs_ad9,
                   @w_ab9   = rs_ab9 
            from cv_reporte_recuperacion_sib
            where rs_fecha_proceso   = @w_fecha_fin9
            and   rs_oficina_procesa = @w_ofi_procesa
         end   
         execute @w_num_error = sp_recupera_tcartera 
                 @t_trn         = 76283, 
                 @i_operacion   = 'G', 
                 @i_opcion      = 'B',  
                 @i_fecha_desde = @w_fecha_desde_tri,
                 @i_fecha_hasta = @w_fecha_hasta,
                 @s_user        = @w_user_batch,
                 @s_term        = @w_term_batch,
                 @s_ofi         = @w_oficina_batch 
                                 
         select  @w_cont= @w_mes_tri_ini       
         
         while @w_cont <= @w_mes         
         begin               
           
            select @w_mes_ejec  = str(@w_cont,2)
            select @w_dia_ejec = day(dateadd(dd,-1,dateadd(dd,(day(@w_mes_ejec + '/01/' + @w_anio_ejec)-1)*-1,dateadd(mm,1, @w_mes_ejec + '/01/' + @w_anio_ejec))))               
             
            select @w_fecha_ini       = @w_mes_ejec + '/01/' + @w_anio_ejec,
                   @w_fecha_fin       = convert(datetime, (@w_mes_ejec +'/'+ str(@w_dia_ejec,2) +'/'+@w_anio_ejec),101)
            select @w_fecha_inicial = CONVERT (char(10), @w_fecha_ini, 112),
                   @w_fecha_final   = CONVERT (char(10), @w_fecha_fin, 112)      
            
            --RECUPERACION POR REMATES ADJUDICADOS       
            select @w_remate_adjudicado = sum(re_monto)
            from cv_recuperaciones
            where re_oficina         = isnull(@w_ofi_procesa,re_oficina) 
            and   re_tipo            = 'ADJUDICACION' 
            and   re_user            = @w_user_batch
            and   re_ofi             = @w_oficina_batch
            and   re_term            = @w_term_batch
            and   CONVERT (char(10),re_fecha_mov,112) >= @w_fecha_inicial and CONVERT (char(10),re_fecha_mov,112) <= @w_fecha_final
            and   re_considerar = 'S'
            
            
            --Recuperaciones por abono
            select @w_recau_efec = sum(po_monto_pago)
            from cv_pagos_op
            where po_oficina_procesa = isnull(@w_ofi_procesa,po_oficina_procesa)            
            and   po_user            = @w_user_batch
            and   po_ofi             = @w_oficina_batch
            and   po_term            = @w_term_batch
            and   po_forma_pago      = 'EFECTIVO'
            and   convert(char(10),po_fecha_pago ,112) >= @w_fecha_inicial and CONVERT (char(10),po_fecha_pago,112) <= @w_fecha_final                     
            
            --RECUPERACION POR REGPROGRAMACIONES, se deben considerar las recuperaciones de tipo: NOVACION/PLAN DE PAGOS/REESTRUCTURACIONES/DACION.
            select @w_recau_nova = sum(re_monto)
            from cv_recuperaciones
            where re_oficina = isnull(@w_ofi_procesa,re_oficina) 
            and   re_tipo      in ('NOVACION', 'PLAN DE PAGO', 'REESTRUCTURACION', 'DACION')
            and   re_user            = @w_user_batch
            and   re_ofi             = @w_oficina_batch
            and   re_term            = @w_term_batch
            and   convert(char(10),re_fecha_mov ,112) >= @w_fecha_inicial and CONVERT (char(10),re_fecha_mov,112) <= @w_fecha_fin
            and   re_considerar = 'S'
            
            select @w_abono = isnull(@w_recau_efec,0) + isnull(@w_recau_nova,0)       
            
            if (@w_abono=0)    
               select @w_abono = null
            
            /*       
            if (@w_cont = 2)
            begin
               select w_recau_efec = @w_recau_efec,
                      w_fecha_inicial = @w_fecha_inicial,
                      w_fecha_final   = @w_fecha_final,
                      w_ofi_procesa = @w_ofi_procesa,
                      w_user_batch  = @w_user_batch,
                      w_oficina_batch = @w_oficina_batch,
                      w_term_batch = @w_term_batch,
                      w_recau_nova = @w_recau_nova,
                      w_abono =@w_abono                      
            end
            */
            
            if @w_mes_tri_ini = 1
            begin            
               if (@w_cont = 1)
               begin
                  select @w_ad1   = @w_remate_adjudicado,
                         @w_ab1   = @w_abono    
               end 
               else 
               if (@w_cont = 2)
               begin
                  select @w_ad2   = @w_remate_adjudicado,
                         @w_ab2   = @w_abono    
               end      
               else
               if (@w_cont = 3)
               begin
                  select @w_ad3   = @w_remate_adjudicado,
                         @w_ab3   = @w_abono    
               end 
            end                 
            else if @w_mes_tri_ini = 4
            begin
               if (@w_cont = 4)
               begin
                  select @w_ad4   = @w_remate_adjudicado,
                         @w_ab4   = @w_abono    
               end      
               else 
               if (@w_cont = 5)
               begin
                  select @w_ad5   = @w_remate_adjudicado,
                         @w_ab5   = @w_abono    
               end      
               else
               if (@w_cont = 6)
               begin
                  select @w_ad6   = @w_remate_adjudicado,
                         @w_ab6   = @w_abono    
               end
            end                 
            else if @w_mes_tri_ini = 7
            begin
               if (@w_cont = 7)
               begin
                  select @w_ad7   = @w_remate_adjudicado,
                         @w_ab7   = @w_abono    
               end
               else      
               if (@w_cont = 8)
               begin
                  select @w_ad8   = @w_remate_adjudicado,
                         @w_ab8   = @w_abono    
               end      
               else
               if (@w_cont = 9)
               begin
                  select @w_ad9   = @w_remate_adjudicado,
                         @w_ab9   = @w_abono    
               end 
            end  
            else if @w_mes_tri_ini = 10   
            begin
               if (@w_cont = 10)
               begin
                  select @w_ad10   = @w_remate_adjudicado,
                         @w_ab10   = @w_abono    
               end      
               else
               if (@w_cont = 11)
               begin
                  select @w_ad11   = @w_remate_adjudicado,
                         @w_ab11   = @w_abono    
               end      
               
               else
               if (@w_cont = 12)
               begin
                  select @w_ad12   = @w_remate_adjudicado,
                         @w_ab12   = @w_abono    
               end      
            end            
            
            select @w_cont=@w_cont+1
         end                 
         
           --Inserto Datos                          
          insert cv_reporte_recuperacion_sib 
                 (   rs_fecha_proceso,   rs_secuencial,   rs_oficina_procesa,   rs_doficina_procesa,
                    rs_trimestre,       rs_ad1,          rs_ab1,               rs_ad2,   
                    rs_ab2,             rs_ad3,          rs_ab3,               rs_ad4,   
                    rs_ab4,             rs_ad5,          rs_ab5,               rs_ad6,   
                    rs_ab6,             rs_ad7,          rs_ab7,               rs_ad8,   
                    rs_ab8,             rs_ad9,          rs_ab9,               rs_ad10,   
                    rs_ab10,            rs_ad11,         rs_ab11,              rs_ad12,   
                    rs_ab12)
         values (   @i_fecha,           @w_contador,     @w_ofi_procesa,       @w_dofi_procesa,
                    @w_mes,             @w_ad1,          @w_ab1,               @w_ad2,   
                    @w_ab2,             @w_ad3,          @w_ab3,               @w_ad4,   
                    @w_ab4,             @w_ad5,          @w_ab5,               @w_ad6,   
                    @w_ab6,             @w_ad7,          @w_ab7,               @w_ad8,   
                    @w_ab8,             @w_ad9,          @w_ab9,               @w_ad10,   
                    @w_ab10,            @w_ad11,         @w_ab11,              @w_ad12,   
                    @w_ab12)
               
         select @w_ad1  = null,             @w_ab1  = null,          @w_ad2  = null,        @w_ab12 = null,   
                @w_ab2  = null,             @w_ad3  = null,          @w_ab3  = null,        @w_ad4  = null,   
                @w_ab4  = null,             @w_ad5  = null,          @w_ab5  = null,        @w_ad6  = null,   
                @w_ab6  = null,             @w_ad7  = null,          @w_ab7  = null,        @w_ad8  = null,   
                @w_ab8  = null,             @w_ad9  = null,          @w_ab9  = null,        @w_ad10 = null,   
                @w_ab10 = null,             @w_ad11 = null,          @w_ab11 = null,        @w_ad12 = null
               
          if @@error != 0
          begin
             select @w_num_error = 760145  --Error en la generacion de reporte
             goto errores                  
          end  
          
         fetch cursor_oficinas into @w_ofi_procesa, @w_dofi_procesa
      end
      
      close cursor_oficinas
      deallocate cursor cursor_oficinas
  
   end 
   
end

---------------------------
-- Presentacion de datos --
---------------------------
if @i_operacion = 'P'
begin

   select @w_mes_fecha = CASE datepart(MONTH,@i_fecha) 
                            when 1  then 'ENERO' 
                            when 2  then 'FEBRERO' 
                            when 3  then 'MARZO' 
                            when 4  then 'ABRIL' 
                            when 5  then 'MAYO' 
                            when 6  then 'JUNIO' 
                            when 7  then 'JULIO' 
                            when 8  then 'AGOSTO' 
                            when 9  then 'SEPTIEMBRE' 
                            when 10 then 'OCTUBRE' 
                            when 11 then 'NOVIEMBRE' 
                            when 12 then 'DICIEMBRE' 
                         end

   select @w_mes_fecha_desde = CASE datepart(MONTH,@w_fecha_desde) 
                                  when 1  then 'ENERO' 
                                  when 2  then 'FEBRERO' 
                                  when 3  then 'MARZO' 
                                  when 4  then 'ABRIL' 
                                  when 5  then 'MAYO' 
                                  when 6  then 'JUNIO' 
                                  when 7  then 'JULIO' 
                                  when 8  then 'AGOSTO' 
                                  when 9  then 'SEPTIEMBRE' 
                                  when 10 then 'OCTUBRE' 
                                  when 11 then 'NOVIEMBRE' 
                                  when 12 then 'DICIEMBRE' 
                               end 

   select @w_mes_fecha_desde_tri = CASE datepart(MONTH,@w_fecha_desde_tri) 
                                      when 1  then 'ENERO' 
                                      when 2  then 'FEBRERO' 
                                      when 3  then 'MARZO' 
                                      when 4  then 'ABRIL' 
                                      when 5  then 'MAYO' 
                                      when 6  then 'JUNIO' 
                                      when 7  then 'JULIO' 
                                      when 8  then 'AGOSTO' 
                                      when 9  then 'SEPTIEMBRE' 
                                      when 10 then 'OCTUBRE' 
                                      when 11 then 'NOVIEMBRE' 
                                      when 12 then 'DICIEMBRE' 
                                   end 
                                   
   if @i_opcion = '1'--Inventarios
   begin     
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = is_secuencial,
                'SECUENCIAL_JUICIO'        = is_secuencia_ju,
                'NO_JUICIO'                = is_num_juicio,
                'ANIO'                     = is_anio,
                'COACTIVADO'               = is_coactivado,  
                'GARANTE'                  = is_garante,     
                'AUTO_PAGO'                = is_fec_auto_pago,   
                'CUANTIA INICIAL'          = is_cuantia_inicial,
                'RIESGO_ACTUAL'            = is_riesgo_actual,
                'ETAPA_PROCESAL'           = is_etapa_procesa,
                'FECHA_ULTIMA_PROVIDENCIA' = is_fec_ult_providencia,    
                'OBSERVACIONES'            = is_observacion,   
                'ABOGADO_IMPULSOR'         = is_abogado,
                'CODIGO_OFICINA_PROCESA'   = is_oficina_procesa,
                'NOMBRE_OFICINA_PROCESA'   = is_doficina_procesa
         from cv_reporte_inventario_sib
         where is_oficina_procesa = isnull(@i_oficina, is_oficina_procesa)    
         order by is_oficina_procesa, is_secuencial, is_secuencia_ju
   end
   
   if @i_opcion = '2'--Archivados
   begin      
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde_tri +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),         
                'SECUENCIAL'               = as_secuencial,
                'SECUENCIAL_JUICIO'        = as_secuencia_ju,
                'REGIONAL'                 = as_doficina_procesa,                                       
                'NO_JUICIO'                = as_num_juicio,
                'ANIO'                     = as_anio,
                'COACTIVADO'               = as_coactivado,  
                'CUANTIA INICIAL'          = as_cuantia_inicial,     
                'RIESGO_ACTUAL'            =  case (isnull(as_riesgo_actual,0)) 
                                              when 0 then 'CANCELADA'
                                              else
                                                 CONVERT(VARCHAR,as_riesgo_actual)                                                
                                              end,
                'FECHA_CAN_PRO'            = as_fec_can_providencia,
                'FECHA_ARC_PRO'            = as_fec_arc_providencia,
                'CODIGO_OFICINA_PROCESA'   = as_oficina_procesa,
                'FORMA_PAGO'               = as_forma_pago
         from cv_reporte_archivado_sib
         where as_oficina_procesa = isnull(@i_oficina, as_oficina_procesa)    
         order by as_oficina_procesa, as_secuencial, as_secuencia_ju                                
   end   
   
   if @i_opcion = '3'--Embargos
   begin      
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = es_secuencial,
                'SECUENCIAL_EMBARGO'       = es_secuencial_emb,             
                'SECUENCIAL_JUICIO'        = es_secuencia_ju,
                'REGIONAL'                 = es_doficina_procesa,                                       
                'NO_JUICIO'                = es_num_juicio,
                'COACTIVADO'               = es_coactivado,
                'FECHA_EMBARG'             = es_fec_embargo,  
                'TIPO_BIEN'                = es_tipo_bien,     
                'FECHA_EMBARGO_INS'        = es_fec_embargo_ins, 
                'OBSERVACION'              = es_observacion,
                'CODIGO_OFICINA_PROCESA'   = es_oficina_procesa
         from cv_reporte_embargo_sib
         where es_oficina_procesa = isnull(@i_oficina, es_oficina_procesa)    
         order by es_oficina_procesa, es_secuencial, es_secuencial_emb                             
   end   

   if @i_opcion = '4'--Adjudicaciones
   begin  
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = as_secuencial,
                'SECUENCIAL_ADJ'           = as_secuencia_adj,             
                'SECUENCIAL_JUICIO'        = as_secuencia_ju,
                'REGIONAL'                 = as_doficina_procesa,             
                'NO_JUICIO'                = as_num_juicio,
                'COACTIVADO'               = as_coactivado,
                'DESC_BIEN'                = as_desc_bien,  
                'FECHA_EMBARG'             = as_fec_isncripcion,     
                'CODIGO_OFICINA_PROCESA'   = as_oficina_procesa
         from cv_reporte_adjudicacion_sib
         where as_oficina_procesa = isnull(@i_oficina, as_oficina_procesa)    
         order by as_oficina_procesa, as_secuencial, as_secuencia_adj       
   end   

   if @i_opcion = '5'--Excepciones
   begin      
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde_tri +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = es_secuencial,
                'SECUENCIAL_EXC'           = es_accion_sec,             
                'SECUENCIAL_JUICIO'        = es_secuencia_ju,             
                'REGIONAL'                 = es_doficina_procesa,             
                'NO_JUICIO'                = es_num_juicio,
                'CUANTIA_INICIAL'          = es_cuantia_inicial,
                'NO_JUICIO_EXC'            = es_num_juicio_exc,
                'JUZGADO'                  = es_juzgado,
                'ESTADO_PROCESAL'          = es_estado_procesal,             
                'FECHA_ULT_PROVIDENCIA'    = es_fec_ult_providencia,
                'OBSERVACION'              = es_observacion,             
                'CODIGO_OFICINA_PROCESA'   = es_oficina_procesa
         from cv_reporte_excepcion_sib
         where es_oficina_procesa = isnull(@i_oficina, es_oficina_procesa)    
         order by es_oficina_procesa, es_secuencial, es_accion_sec
   end   
   
   if @i_opcion = '6'--Insolvencias
   begin      
         --Consultar informacion         
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde_tri +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = is_secuencial,
                'SECUENCIAL_INS'           = is_quiebra_sec,             
                'SECUENCIAL_JUICIO'        = is_secuencia_ju,             
                'REGIONAL'                 = is_doficina_procesa,             
                'NO_JUICIO'                = is_num_juicio,
                'JUEZ_CAUSA'               = is_juez,
                'DEMANDADO'                = is_demandado,
                'ESTADO_PROCESO'           = is_estado_pro,
                'FECHA_ULT_PROVIDENCIA'    = is_fec_ult_providencia,
                'OBSERVACION'              = is_observacion,             
                'CODIGO_OFICINA_PROCESA'   = is_oficina_procesa
         from cv_reporte_insolvencia_sib
         where is_oficina_procesa = isnull(@i_oficina, is_oficina_procesa)    
         order by is_oficina_procesa, is_secuencial, is_quiebra_sec
   end      


   if @i_opcion = '7'--Recuperaciones
   begin      
         --Consultar informacion         
         select 'FECHA_PROCESO'            = 'DESDE 01 '+ @w_mes_fecha_desde_tri +' AL '+str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
                'SECUENCIAL'               = rs_secuencial,
                'TRIMESTRE'                = rs_trimestre,
                'CODIGO_OFICINA_PROCESA'   = rs_oficina_procesa,                
                'CIUDAD_JUZGADO'           = rs_doficina_procesa,             
                'REMATES_ADJUDICADOS_1'    = rs_ad1,
                'POR_ABONOS_1'             = rs_ab1,
                'REMATES_ADJUDICADOS_2'    = rs_ad2,
                'POR_ABONOS_2'             = rs_ab2,
                'REMATES_ADJUDICADOS_3'    = rs_ad3,
                'POR_ABONOS_3'             = rs_ab3,
                'REMATES_ADJUDICADOS_4'    = rs_ad4,
                'POR_ABONOS_4'             = rs_ab4,
                'REMATES_ADJUDICADOS_5'    = rs_ad5,
                'POR_ABONOS_5'             = rs_ab5,
                'REMATES_ADJUDICADOS_6'    = rs_ad6,
                'POR_ABONOS_6'             = rs_ab6,
                'REMATES_ADJUDICADOS_7'    = rs_ad7,
                'POR_ABONOS_7'             = rs_ab7,
                'REMATES_ADJUDICADOS_8'    = rs_ad8,
                'POR_ABONOS_8'             = rs_ab8,
                'REMATES_ADJUDICADOS_9'    = rs_ad9,
                'POR_ABONOS_9'             = rs_ab9,
                'REMATES_ADJUDICADOS_10'    = rs_ad10,
                'POR_ABONOS_10'             = rs_ab10,
                'REMATES_ADJUDICADOS_11'    = rs_ad11,
                'POR_ABONOS_11'             = rs_ab11,
                'REMATES_ADJUDICADOS_12'    = rs_ad12,
                'POR_ABONOS_12'             = rs_ab12
         from cv_reporte_recuperacion_sib
         where rs_oficina_procesa = isnull(@i_oficina, rs_oficina_procesa) 
         and   rs_fecha_proceso   =  @i_fecha  
         order by rs_oficina_procesa, rs_secuencial
   end      
   
end
goto fin
-----------------------------------------
--Control errores
-----------------------------------------
errores:
   while @@trancount > 0 
      rollback tran

   if @w_commit = 'S' 
      commit tran     
              
   return @w_num_error
fin:
   return 0
go
grant exec on cob_coactiva..sp_reporte_cuadro_sib to reports
go
set replication on
go

