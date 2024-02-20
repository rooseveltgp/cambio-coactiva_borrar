IF OBJECT_ID ('dbo.sp_reporte_estado_juridico') IS NOT NULL
	DROP PROCEDURE dbo.sp_reporte_estado_juridico
GO

create proc sp_reporte_estado_juridico
(      
   @i_operacion                     char(1),             --Operacion a Ejecutar   
   @i_opcion                        char(1)     = '',    --Opcion a ejecutar dentro de una operacion   
   @i_fecha                         datetime    = null,  --Fecha de proceso
   @i_oficina                       smallint    = null   --Oficina de generacion datos
 )
as
declare
   @w_sp_name                    varchar(32),            --nombre del stored procedure     
   @w_num_error                  int,                    --numero de error  
   @w_commit                     char(1),                --flag para verificar si debe hacer commit tran
   @w_tabla_estado_juicio        int,                    --Tabla catalogo de Estaos de Juicio
   
   -----------------------------------
   --Variables para manejo del reporte
   -----------------------------------
   @w_fecha                   varchar(12) ,              --Fecha formateada
   @w_fecha_proceso           datetime    ,              --Fecha de proceso de la base
   @w_fecha_borra             datetime    ,              --Fecha desde donde se borran datos
   @w_fecha_fmes_1            datetime    ,              --Fecha de primer fin de mes atras a la fecha de proceso
   @w_fecha_fmes_2            datetime    ,              --Fecha de segundo fin de mes atras a la fecha de proceso
   @w_fecha_fmes_3            datetime    ,              --Fecha de tercer fin de mes atras a la fecha de proceso
   @w_juicio_sec              int         ,              --Secuencial del juicio      
   @w_ced_ruc                 varchar(50) ,              --Cedula Ruc  del coactivado
   @w_ced_conyuge             varchar(20) ,              --Cedula de conyuge de coactivado
   @w_juicio                  varchar(24),               --Numero del juicio   
   @w_coactivado              varchar(200),              --Nombre del coactivado
   @w_conyuge                 varchar(100),              --Nombre del conyuge del coactivado   
   @w_operacion               varchar(300),              --Operacion coactivada
   @w_operacion_asiento       varchar(24) ,              --Operacion asiento  
   @w_cuantia_inicial         money       ,              --Cuantia inicial del juicio
   @w_fec_sol_coactiva        datetime    ,              --Numero de solicitud de coactiva
   @w_fec_orden_cobro         datetime    ,              --Fecha de orden cobro
   @w_secretario              varchar(100),              --Nombre del secretario del juicio
   @w_fec_auto_pago           datetime    ,              --Fecha de auto de pago
   @w_sec_bien                int         ,              --Secuencial del Bien
   @w_fec_embargo             varchar(120),              --Fecha de Embargo del bien   
   @w_fec_insc_emb            varchar(120),              --Fecha de inscripcion del embargo   
   @w_fec_ult_citacion        varchar(10) ,              --Fecha de ultima citacion
   @w_nom_perito              varchar(200),              --Nombre del perito avaluador   
   @w_fechas_ava              varchar(120),              --Fechas de avaluo
   @w_valores_ava             varchar(120),              --Valores de los avaluos
   @w_fec_remate              varchar(120),              --Fecha de remate del bien
   @w_fec_calificacion        varchar(90) ,              --Fecha de calificacion
   @w_fec_adjudicacion        varchar(100),              --Fecha de adjudicacion del bien
   @w_linea                   tinyint     ,              --Numero de lina de la observacion
   @w_maximo                  tinyint     ,              --Maximo observaciones de un juicio   
   @w_linea_observa           varchar(1000),             --Observaciones del juicio por linea 1     
   @w_observacion             varchar(8000),             --Observaciones del juicio     
   @w_max_lin_observacion     tinyint,                   --Máxima lineas de observacion a presentar
   @w_pos                     int,                       --Contador de cadena   
   @w_contador                int,                       --Contador para insertar secuencial en base a operaciones de juicio      
   @w_cont_avaluo	            int,                       --Contador de existencia de avaluos
   @w_cont_embargo            int,                       --Contador de existencia de embargos
   @w_cont_adjudicacion       int,                       --Contador de existencia de adjudicacion
   @w_cont_remate_s1          int,                       --Contador de existencia de remate 1
   @w_cont_remate_s2          int,                       --Contador de existencia de remate 2
   @w_cont_remate             int,                       --Contador de Remates
   @w_estado_archivado        varchar(10),               --Estado archivado del Juicio
   @w_memo_sol_coactiva       varchar(20),               --Memo de solicitud de coactivado
   @w_estado_anualdo          varchar(10),               --Estado anulado el Juicio      
   @w_memo_fec_sol_coactiva   varchar(40),               --Memo y fecha de solicitud de coactivado
   @w_mes                     varchar(3),                --Mes de fecha
   @w_mes_ejec                varchar(2),                --Mes de fecha
   @w_anio_ejec               varchar(4),                --anio de fecha
   @w_dia_ejec                int,                       --dia de fecha
   @w_fecha_fin_mes           datetime,                  --fecha de fin de mes laborable   
   @w_oficina_batch           smallint,                  --fecha de fin de mes laborable      
   @w_cant_fechas             int,                       --Cantidad de fechas diferentes de los datos procesados en el reporte
   @w_min_fecha               datetime,                  --Minima fecha de los datos procesados en el reporte   
   @w_dofi_procesa            varchar(64),               --Oficina Procesa
   @w_ofi_procesa             smallint,                  --Codigo de oficina procesa
   @w_mes_fecha               varchar(10)                --Mes de fecha procesa     
 
select @w_sp_name = 'sp_reporte_estado_juridico'  

--Validando Fecha de Proceso
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

--------------------------------------
--Inicializacion de Variables
--------------------------------------
select @w_commit              = 'N',
       @w_max_lin_observacion = 5       

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

select @w_oficina_batch = pa_smallint 
from cobis..cl_parametro
where pa_nemonico = 'OFEB'
and pa_producto = 'COA'

if @i_oficina = 0
   select @i_oficina = null
   
-------------------------
-- Generacion de datos --
-------------------------
if @i_operacion = 'G'
begin
   if @i_opcion = '1'
   begin
      --Valido que le fecha ingresada sea igual a la fecha de fin de mes laborable
      select @w_mes_ejec  = str(datepart(mm,@i_fecha),2),
             @w_anio_ejec = str(datepart (yy, @i_fecha),4) 
   
      select @w_dia_ejec = day(dateadd(dd,-1,dateadd(dd,(day(@w_mes_ejec + '/01/' + @w_anio_ejec)-1)*-1,dateadd(mm,1, @w_mes_ejec + '/01/' + @w_anio_ejec))))
   
      select @w_fecha_fin_mes = convert(datetime, (@w_mes_ejec +'/'+str(@w_dia_ejec,2) +'/'+@w_anio_ejec),101)
   
      while 1=1
      begin
         if exists (select 1 from cobis..cl_dias_feriados
                    where df_fecha   = @w_fecha_fin_mes
                    and   df_ciudad  = @w_oficina_batch)
            select @w_fecha_fin_mes =  dateadd(DAY,-1,@w_fecha_fin_mes)   
         else
           break
      end
   
      if @i_fecha != @w_fecha_fin_mes
      begin   
         select @w_fecha = convert(varchar,@i_fecha,101)
         print 'la fecha ingresada no es fin de mes laborable'
         return 0
      end   
  
      --Validar fecha de reporte   
      if @i_fecha >= @w_fecha_proceso
      begin 
         if not exists (select 1
                        from cv_reporte_estado_juridico
                        where re_fecha_proceso =  @i_fecha)
         begin  
            select @w_cant_fechas = count(distinct(re_fecha_proceso))  
            from cv_reporte_estado_juridico
               
            if @w_cant_fechas > 5
            begin
               select @w_min_fecha = min (re_fecha_proceso)
               from cv_reporte_estado_juridico
                  
               delete cv_reporte_estado_juridico      
               where re_fecha_proceso =  @w_min_fecha
            
               if @@error != 0
               begin
                  select @w_num_error = 760005 --error eliminando registros
                  goto errores
               end
            end 
         end
         else
         begin
            delete cv_reporte_estado_juridico      
            where re_fecha_proceso =  @i_fecha
               
            if @@error != 0
            begin
               select @w_num_error = 760005 --error eliminando registros
               goto errores
            end
         end
      end
      else
      begin
         if not exists (select 1
                       from cv_reporte_estado_juridico
                       where re_fecha_proceso =  @i_fecha)
         begin  
            select @w_fecha = convert(varchar,@i_fecha,101)
            print 'No existen datos para reprocesar a la fecha %1!', @w_fecha
            return 0   
         end
         return 0
      end  
      
      select @w_cuantia_inicial  = null,
             @w_contador         = 0   
             
      --Genero datos del reporte      
      Declare  cur_juicio  cursor for
      select   j.ju_juicio_sec,             j.ju_juicio,              f.en_ced_ruc,                 isnull(f.en_nomlar, f.en_nombre),  
               j.ju_monto_inicial_juicio,   j.ju_memo_sol_coactiva,   j.ju_fecha_sol_coactiva,      j.ju_fecha_orden_cobro,
               r.re_nombre,                 j.ju_fecha_auto_pago,     j.ju_oficina_procesa,         d.of_nombre    
      from cv_juicio j, cobis..cl_ente f, cv_responsables r,cobis..cl_oficina d
      where f.en_ente              =* j.ju_ente_deudor
      and   r.re_codigo            =* j.ju_cod_secretario
      and   j.ju_oficina_procesa =  d.of_oficina
      and  (j.ju_estado <> @w_estado_archivado or j.ju_estado <> @w_estado_anualdo) 
      order by j.ju_oficina_procesa, convert(int,substring(j.ju_juicio,1,4)),substring(j.ju_juicio,6,4)
      
      Open cur_juicio 
      Fetch cur_juicio into @w_juicio_sec,            @w_juicio,             @w_ced_ruc,              @w_coactivado,
                            @w_cuantia_inicial,       @w_memo_sol_coactiva,  @w_fec_sol_coactiva,     @w_fec_orden_cobro,   
                            @w_secretario,            @w_fec_auto_pago,      @w_ofi_procesa,          @w_dofi_procesa
		                       
      While @@sqlstatus != 2
      begin 
         select @w_contador = @w_contador + 1      	      	 	                
        
         --Obtener el conyugue del coactivado si existe
         select @w_conyuge = '' 
         
         select @w_conyuge     = isnull(en_nomlar, en_nombre),
                @w_ced_conyuge = en_ced_ruc
         from  cv_juicio_deudores, cobis..cl_ente
         where jd_juicio_sec = @w_juicio_sec         
         and   jd_rol        = 'Y'  --Conyugue
         and   en_ente       = jd_ente_deudor 
                      
         if @w_conyuge != '' and @w_conyuge is not null
         begin
            select @w_pos = 0
            select @w_pos = CHARINDEX(@w_ced_conyuge, @w_ced_ruc)            
            if @w_pos = 0 and ltrim(rtrim(@w_ced_conyuge)) != '' and @w_ced_conyuge is not null
            begin
               if @w_ced_ruc = ''
                  select @w_ced_ruc = @w_ced_conyuge
               else
                  select @w_ced_ruc = @w_ced_ruc + ' / ' + @w_ced_conyuge
            end
                  
            select @w_pos = 0   
            select @w_pos = CHARINDEX(@w_conyuge, @w_coactivado)            
            if @w_pos = 0 and ltrim(rtrim(@w_conyuge)) != '' and @w_conyuge is not null
            begin
               if  @w_coactivado  = ''
                  select @w_coactivado = @w_conyuge                  
               else                  
                  select @w_coactivado = @w_coactivado + ' / ' + @w_conyuge                  
            end
               
         end
         
         --Obtener Numero de la operación y/o asiento contable: se deberán incluir las operaciones que hubieren dentro de un mismo juicio 
         select @w_operacion = ''                                         
            	
         declare cur_operaciones cursor for
         select jo_operacion_asiento
         from cv_juicio_operacion
         where jo_juicio_sec = @w_juicio_sec         
                
         Open cur_operaciones
         Fetch  cur_operaciones into @w_operacion_asiento
         While @@sqlstatus != 2
         begin 
            if @w_operacion_asiento != null or @w_operacion_asiento != ''
            begin                          
               select @w_pos = 0
               select @w_pos = CHARINDEX(@w_operacion_asiento, @w_operacion)
               if @w_pos = 0 and ltrim(rtrim(@w_operacion_asiento)) != '' and @w_operacion_asiento is not null
                  if @w_operacion = ''
                     select @w_operacion =  @w_operacion_asiento                                       
                  else
                     select @w_operacion = @w_operacion + ' / ' + @w_operacion_asiento                                                                             
            end
            Fetch  cur_operaciones into @w_operacion_asiento
         end
         
         close cur_operaciones
         deallocate cursor cur_operaciones
         
         --Obtengo el memo y fecha de solicitud de coactiva
         select @w_mes = CASE datepart(MONTH,@w_fec_sol_coactiva) 
                         when 1  then 'Ene' 
                         when 2  then 'Feb' 
                         when 3  then 'Mar' 
                         when 4  then 'Abr' 
                         when 5  then 'May' 
                         when 6  then 'Jun' 
                         when 7  then 'Jul' 
                         when 8  then 'Ago' 
                         when 9  then 'Sep' 
                         when 10 then 'Oct' 
                         when 11 then 'Nov' 
                         when 12 then 'Dic' end
                         
         select @w_memo_fec_sol_coactiva = @w_memo_sol_coactiva +' '+  @w_mes +' '+ str(datepart (dd, @w_fec_sol_coactiva) ,2) +' '+ str(datepart (yy, @w_fec_sol_coactiva) ,4)                        
         select @w_memo_fec_sol_coactiva = LTRIM(RTRIM(@w_memo_fec_sol_coactiva))
         
         --Fecha de Citacion
         select @w_fec_ult_citacion = convert(varchar,ec_fecha_citacion,101)
         from cv_etapa_citacion
         where ec_juicio_sec = @w_juicio_sec
         and  ec_estado = 'V'
         and  ec_id_citacion = (select max(ec_id_citacion) from cv_etapa_citacion where ec_juicio_sec = @w_juicio_sec)
         
         
          --Tomar Observaciones del juicio
         select @w_linea = 1,
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
         		 
         --Verificar si existen datos de bienes por juicio antes de ingresar al cursor		
         --Encerar Variables Contadores        	       
         select @w_cont_avaluo	 = 0,	@w_cont_embargo   = 0, @w_cont_adjudicacion  = 0,     
                @w_cont_remate_s1 = 0, @w_cont_remate_s2 = 0
			
         select @w_cont_avaluo = count(1)
         from cv_avaluo_bien
         where ab_juicio_sec  = @w_juicio_sec         
         and   ab_estado       = 'V'            
			 
         select @w_cont_embargo = count(1)
         from   cv_etapa_embargo
         where  ee_juicio_sec  = @w_juicio_sec
         and    ee_estado      = 'V'  --Vigentes
			 
         select @w_cont_adjudicacion = count(1)
         from   cv_adjudicacion_bien
         where  ab_secuencial_bien in (select jb_secuencial_bien  from cv_juicio_bienes 
                                       where jb_juicio_sec = @w_juicio_sec
                                       and   jb_tipo_bien  is not null)
                                       and   ab_estado     = 'V'  --Vigente
                                        		     
         select @w_cont_remate_s1 = count(1)
         from cv_etapa_remate, cv_bienes_remate
         where er_juicio_sec   = @w_juicio_sec
         and   er_senalamiento = 1
         and   br_id_remate    = er_id_remate
		     
         select @w_cont_remate_s2 = count(1)
         from cv_etapa_remate, cv_bienes_remate
         where er_juicio_sec   = @w_juicio_sec
         and   er_senalamiento = 2
         and   br_id_remate    = er_id_remate		 
	     
         --Apertura del cursor de Bienes
         declare cur_bienes cursor for
         select jb_secuencial_bien
         from cv_juicio_bienes 
         where jb_juicio_sec = @w_juicio_sec                   	
         and  jb_tipo_bien  is not null
         order by jb_secuencial_bien
		 
         Open cur_bienes
         Fetch cur_bienes into @w_sec_bien
         while @@sqlstatus != 2
         begin
            -------------------
            -- OBTENER DATOS --
            -------------------    
            --Obtener datos de avaluo    
            if @w_cont_avaluo > 0
            begin                  
               select @w_fechas_ava  = @w_fechas_ava + convert(varchar,ab_fecha_avaluo,101) + ' - ',
                      @w_valores_ava = @w_valores_ava  + convert(varchar,ab_monto_avaluo,1) + ' / ', 
                      @w_nom_perito  = @w_nom_perito  + is_nombre + ' / '	                  
               from cv_avaluo_bien, cob_custodia..cu_inspector
               where ab_juicio_sec      = @w_juicio_sec
               and   ab_secuencial_bien = @w_sec_bien
               and   is_inspector       = ab_cod_perito
               and   ab_estado          = 'V'            
            end                        
                        
            --Obtener datos del embargo AgruparTodo
            if @w_cont_embargo > 0
            begin               
               select @w_fec_embargo   = @w_fec_embargo   + convert(varchar,ee_fecha_embargo,101) + ' - ', 	                 
                      @w_fec_insc_emb  =(case when ee_fecha_inscripcion is not null 
                                            then @w_fec_insc_emb  + convert(varchar,ee_fecha_inscripcion,101) + ' - '
                                            else @w_fec_insc_emb 
                                         end)	                   
               from   cv_etapa_embargo, cobis..cl_provincia
               where  ee_juicio_sec      = @w_juicio_sec
               and    ee_secuencial_bien = @w_sec_bien
               and    ee_estado    = 'V'  --Vigentes
               and    pv_provincia =  ee_provincia_embargo            
            end
           
            --Fecha de Adjudicacion de bien
            if @w_cont_adjudicacion > 0
            begin
              select @w_fec_adjudicacion = @w_fec_adjudicacion + convert(varchar,ab_fecha_auto_adjudicacion,101) + ' - '		              
              from   cv_adjudicacion_bien
              where  ab_secuencial_bien = @w_sec_bien
              and    ab_estado  = 'V'  --Vigente
            end	  
          
            if @w_cont_remate_s1 > 0 or @w_cont_remate_s2 > 0 
            begin	        
              select @w_fec_remate       =(case when er_fecha_inicio_remate is not null 
                                            then @w_fec_remate + convert(varchar,max(er_fecha_inicio_remate),101) + ' - '
                                            else @w_fec_remate 
                                            end),	
                     @w_fec_calificacion =(case when er_fecha_auto_calificacion is not null 
                                           then @w_fec_calificacion  + convert(varchar,er_fecha_auto_calificacion,101) + ' - '
                                           else @w_fec_calificacion 
                                           end) 
              from cv_etapa_remate, cv_bienes_remate
              where er_juicio_sec      = @w_juicio_sec            	        
              and   br_id_remate       = er_id_remate	        	        
              and   br_secuencial_bien = @w_sec_bien                       
        	        
         end	        
         	            	        				   
             Fetch cur_bienes into @w_sec_bien
         end
         close cur_bienes
         deallocate cursor cur_bienes		                    
			
         --Inserto Datos	
         --Quitar ultimo caracter de "/" o de "-" 		       		       
   			
         select @w_fechas_ava        = substring(@w_fechas_ava       , 1, len(@w_fechas_ava       )-2),
                @w_valores_ava       = substring(@w_valores_ava      , 1, len(@w_valores_ava      )-2),
                @w_nom_perito        = substring(@w_nom_perito       , 1, len(@w_nom_perito       )-2),
                @w_fec_embargo       = substring(@w_fec_embargo      , 1, len(@w_fec_embargo      )-2),
                @w_fec_insc_emb      = substring(@w_fec_insc_emb     , 1, len(@w_fec_insc_emb     )-2),
                @w_fec_adjudicacion  = substring(@w_fec_adjudicacion , 1, len(@w_fec_adjudicacion )-2),
                @w_fec_remate        = substring(@w_fec_remate       , 1, len(@w_fec_remate       )-2),
                @w_fec_calificacion  = substring(@w_fec_calificacion , 1, len(@w_fec_calificacion )-2)
   			       
         insert cv_reporte_estado_juridico 
                (re_fecha_proceso,          re_secuencial,       re_secuencia_ju,       re_juicio,
                 re_ced_ruc,                re_coactivado,       re_operacion,          re_cuantia_inicial,
                 re_sol_coactiva,           re_fec_orden_cobro,  re_secretario,         re_fec_auto_pago,
                 re_fec_embargo,            re_fec_insc_emb,     re_fec_ult_citacion,   re_nom_perito,
                 re_fec_avaluo,             re_val_avaluo,       re_fec_remate,         re_fec_calificacion,
                 re_fec_adjudicacion,       re_observacion,      re_oficina_procesa,    re_doficina_procesa)                
         values (@i_fecha,                  @w_contador,         @w_juicio_sec,         @w_juicio,
                 @w_ced_ruc,                @w_coactivado,       @w_operacion,          @w_cuantia_inicial,
                 @w_memo_fec_sol_coactiva,  @w_fec_orden_cobro,  @w_secretario,         @w_fec_auto_pago,
                 @w_fec_embargo,            @w_fec_insc_emb,     @w_fec_ult_citacion,   @w_nom_perito,
                 @w_fechas_ava,             @w_valores_ava,      @w_fec_remate,         @w_fec_calificacion, 
                 @w_fec_adjudicacion,       @w_observacion,      @w_ofi_procesa,        @w_dofi_procesa)
              
         if @@error != 0
         begin
            select @w_num_error = 760145  --Error en la generacion de reporte
            goto errores                  
         end   
          
         --Encerar Variables  
         select @w_valores_ava       = null,   @w_nom_perito        = null,  @w_fec_embargo       = null, @w_fec_insc_emb  = null,
                @w_fec_ult_citacion  = null,   @w_cuantia_inicial   = null,  @w_fec_adjudicacion  = null, @w_fec_remate    = null, 
                @w_fechas_ava        = null,   @w_fec_calificacion  = null,  @w_observacion       = null, @w_conyuge       = null,  
                @w_ced_conyuge       = null,   @w_ced_ruc           = null,  @w_coactivado        = null
   
          		                  
            Fetch cur_juicio into  @w_juicio_sec,            @w_juicio,             @w_ced_ruc,              @w_coactivado,
                                   @w_cuantia_inicial,       @w_memo_sol_coactiva,  @w_fec_sol_coactiva,     @w_fec_orden_cobro,   
                                   @w_secretario,            @w_fec_auto_pago,      @w_ofi_procesa,          @w_dofi_procesa 			                         
         end
         Close cur_juicio
         Deallocate cursor cur_juicio                         
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
                         when 12 then 'DICIEMBRE' end

   select 'FECHA_PROCESO'            = str(datepart (dd, @i_fecha) ,2) +' '+ @w_mes_fecha + ' DEL '+ str(datepart (yy, @i_fecha) ,4),
          'SECUENCIAL'               = re_secuencial,
          'SECUENCIAL_JUICIO'        = re_secuencia_ju,
          'JUICIO'                   = re_juicio,
          'CI_RUC'                   = re_ced_ruc,
          'NOMBRE_COACTIVADO'        = re_coactivado,
          'OPERACION'                = re_operacion,
          'CUANTIA_INICIAL'          = re_cuantia_inicial,
          'SOL_COACTIVA'             = re_sol_coactiva,          
          'FECHA_ORDEN_COBRO'        = convert(char(10),re_fec_orden_cobro,101),
          'SECRETARIO'               = re_secretario,
          'FECHA_AUTO_PAGO'          = convert(char(10),re_fec_auto_pago,101),
          'FECHA_EMBARGO'            = re_fec_embargo,
          'FECHA_INSCRIP_EMBARGO'    = re_fec_insc_emb,
          'FECHA_ULT_CITACION'       = convert(char(10),re_fec_ult_citacion,101),
          'PERITO_AVALUADOR'         = re_nom_perito,
          'FECHA_AVALUO'             = re_fec_avaluo,
          'VALOR_AVALUO'             = re_val_avaluo,
          'FECHA_REMATE'             = re_fec_remate,
          'FECHA_CALIFICACION'       = re_fec_calificacion,
          'FECHA_ADJUDICACION'       = re_fec_adjudicacion,
          'OBSERVACIONES'            = re_observacion,
          'CODIGO_OFICINA_PROCESA'   = re_oficina_procesa,
          'NOMBRE_OFICINA_PROCESA'   = re_doficina_procesa          
   from cv_reporte_estado_juridico
   where re_fecha_proceso   = @i_fecha 
   and   re_oficina_procesa = isnull(@i_oficina, re_oficina_procesa)    
   order by re_oficina_procesa, re_juicio, re_secuencial, re_secuencia_ju
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

GO

