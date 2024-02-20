

exec  sp_reporte_sib
@i_operacion  =  'P'  ,                  --          char(1),            --Operacion a Ejecutar   
   @i_opcion  = 'G',                      --          char(1)     = '',   --Opcion a ejecutar dentro de una operacion   
   @i_fecha = '2021/12/30' ,       --         datetime    = null, --Fecha de proceso
   @i_oficina = 2                            --          smallint    = null  --Oficina de generacion datos



--select jo_operacion_asiento, jo_anterior, * from cv_juicio_operacion where jo_operacion_asiento <> jo_anterior


select distinct rs_fecha_proceso   from        cv_reporte_sib_parte_1  where  rs_fecha_proceso   = '12/30/2021 0:00:00' 