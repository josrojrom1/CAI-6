# Definimos las tareas y quien puede realizar las tareas segun su rol, aqui se incluye tambien los roles heredados y la restricción R4. 
tareas_asignados = {
    'T1': ['HYV', 'JVG'],
    'T2.1': ['GTR', 'LPG', 'RGB', 'HYV', 'BJC'],
    'T2.2': ['RGB', 'MDS', 'LPG', 'HYV'],
    'T3': ['PGR'],
    'T4.1': ['MFE'],
    'T4.2': ['HJR', 'PTS', 'IHP']
}
#Contador de tareas asignadas a cada persona.
tareas_por_persona = {
    'JVG':0,
    'HYV':0,
    'PGR':0,
    'MFE':0,
    'GTR':0,
    'BJC':0, 
    'LPG':0, 
    'RGB':0, 
    'MDS':0,
    'HJR':0, 
    'PTS':0,
    'IHP':0
}

resultados = []

num_iteraciones = 20

for i in range(num_iteraciones):
    iteracion = {}
    for tarea in tareas_asignados:
        for persona in tareas_por_persona:
            if tarea=='T2.2' and iteracion['T2.1']=='GTR': #Restriccion R3
                iteracion[tarea]='MDS'
                tareas_por_persona['MDS']=tareas_por_persona['MDS']+1
                break
            if persona in tareas_asignados[tarea]:
                if tarea=='T2.2' and iteracion['T2.1']==persona: #Restriccion R2
                    continue
                iteracion[tarea]= persona
                tareas_por_persona[persona] = tareas_por_persona[persona]+1
                break
            
    tareas_por_persona = dict(sorted(tareas_por_persona.items(), key=lambda item: item[1]))
    resultados.append(iteracion)

#Ahora enseñamos los resultados
i = 1
for di in resultados:
    print('Iteración '+ str(i))
    print(' - Tarea 1: '+di['T1'])
    print(' - Tarea 2.1: '+di['T2.1'])
    print(' - Tarea 2.2: '+di['T2.2'])
    print(' - Tarea 3: '+di['T3'])
    print(' - Tarea 4: '+di['T4.1']+ ' y ' +di['T4.2'])
    i +=1

print("Recuento total:")
for a in tareas_por_persona:
    print(a + ' - ' + str(tareas_por_persona[a]))
