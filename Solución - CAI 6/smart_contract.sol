// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Subasta {
    // Dirección del propietario de la subasta
    address payable public owner;
    // Fecha de finalización de la subasta
    uint256 public endDate;
    // Valor de mercado de los medicamentos
    uint256 public mercado;
    // Número máximo de pujadores permitidos
    uint256 public maxPujadores = 30;
    // Bandera para activar/desactivar el bloqueo de pujas
    bool public bloqueoPujas;

    // Constructor que establece al creador del contrato como propietario
    constructor() {
        owner = payable(msg.sender);
    }
    
    // Estructura para almacenar información de las pujas
    struct Puja {
        address payable participante;
        uint256 monto;
        bool activa;
    }

    // Array para almacenar todas las pujas
    Puja[] public pujasArray;
    // Mapping para almacenar las fianzas de cada participante
    mapping(address => uint256) public fianzas;
    // Array para almacenar a los ganadores de la subasta
    Puja[] public ganadores;

    // Eventos para notificar nuevas pujas y finalización de la subasta
    event NuevaPuja(address indexed participante, uint256 monto);
    event SubastaFinalizada(address[] ganadores, uint256[] montos);

    // Función para establecer el valor de mercado de los medicamentos
    function valorMercado(uint256 valor) public returns (uint256) {
        require(msg.sender == owner, "Solo el owner puede modificar el valor de mercado");
        mercado = valor;
        return mercado;
    }

    // Función para establecer la fecha de finalización de la subasta
    function fechaFin(uint256 dias) public returns (uint256) {
        require(msg.sender == owner, "Solo el owner puede modificar la fecha de finalización");
        endDate = block.timestamp + dias * 86400;
        return endDate;
    }

    // Función para activar el bloqueo temporal de pujas
    function activarBloqueoPujas() public {
        require(msg.sender == owner, "Solo el owner puede activar el bloqueo de pujas");
        bloqueoPujas = true;
    }

    // Función para desactivar el bloqueo temporal de pujas
    function desactivarBloqueoPujas() public {
        require(msg.sender == owner, "Solo el owner puede desactivar el bloqueo de pujas");
        bloqueoPujas = false;
    }

    // Función para realizar una puja
    function pujar(uint256 monto) public payable {
        // Validaciones de la puja
        // ----- Monto positivo
        require(monto > 0, "La puja debe ser un valor entero positivo");
        // ----- Monto menor al valor del mercado
        require(monto < mercado, "La puja no debe superar el valor de mercado");
        // ----- Límite de pujadores
        require(pujasArray.length < maxPujadores, "Se ha alcanzado el límite de pujadores");
        // ----- Fin de subasta
        require(block.timestamp < endDate, "La subasta ha finalizado");
        // ----- Envío de la cantidad exacta
        require(msg.value == monto, "Debes enviar la cantidad exacta de la puja");

        // Si el bloqueo de pujas está activado, se verifica que el timestamp sea PAR para evitar pujas simultáneas
        if (bloqueoPujas) {
            require(block.timestamp % 2 == 0, "Espere un momento y vuelva a intentar la puja");
        }
        
        // Se verifica que el participante no haya pujado anteriormente
        for (uint256 i = 0; i < pujasArray.length; i++) {
            require(pujasArray[i].participante != msg.sender, "No se permiten pujas duplicadas");
        }

        // Se agrega la puja al array y se almacena la fianza en el mapping
        pujasArray.push(Puja(payable(msg.sender), monto, true));
        fianzas[msg.sender] = monto;

        // Se emite el evento de nueva puja
        emit NuevaPuja(msg.sender, monto);

        // Si se alcanza el límite de pujadores o se supera la fecha de finalización, se llama a la función para finalizar la subasta
        if (pujasArray.length == maxPujadores || block.timestamp >= endDate) {
            finalizarSubasta();
        }
    }

    // Función privada para finalizar la subasta
    function finalizarSubasta() private {
        
        // Se verifica que se haya superado la fecha de finalización
        require(block.timestamp >= endDate, "La subasta aún no ha finalizado");

        // Se inicializan variables para almacenar la puja ganadora y la segunda puja más baja
        uint256 pujaGanadora = type(uint256).max;
        uint256 pujaSegunda = type(uint256).max;

        // Se recorre el array de pujas para determinar la puja ganadora y la segunda puja más baja
        for (uint256 i = 0; i < pujasArray.length; i++) {
            if (pujasArray[i].monto < pujaGanadora && pujasArray[i].activa) {
                pujaSegunda = pujaGanadora;
                pujaGanadora = pujasArray[i].monto;
            } else if (pujasArray[i].monto < pujaSegunda && pujasArray[i].activa && pujasArray[i].monto != pujaGanadora) {
                pujaSegunda = pujasArray[i].monto;
            }
        }
        
        // Se recorre nuevamente el array de pujas para:
        for (uint256 i = 0; i < pujasArray.length; i++) {
            //----- Agregar a los ganadores al array de ganadores (si la puja coincide con la puja ganadora)
            if (pujasArray[i].monto == pujaGanadora) {
                ganadores.push(pujasArray[i]);
            } else if (pujasArray[i].activa) {
                //----- Devolver las fianzas a los participantes no ganadores (si la puja está activa y no es la puja ganadora)
                pujasArray[i].participante.transfer(fianzas[pujasArray[i].participante]);
                fianzas[pujasArray[i].participante] = 0;
            }
        }
        // Se crea un array dinámico para almacenar las direcciones y montos de los ganadores

        address[] memory ganadoresArray = new address[](ganadores.length);
        uint256[] memory montosArray = new uint256[](ganadores.length);
        // Se recorre el array de ganadores para:

        for (uint256 i = 0; i < ganadores.length; i++) {
            // Asignar las direcciones de los ganadores al array dinámico
            ganadoresArray[i] = ganadores[i].participante;
            // Asignar la segunda puja más baja como monto a pagar a cada ganador
            montosArray[i] = pujaSegunda;
            // Establecer las fianzas de los ganadores en 0
            fianzas[ganadores[i].participante] = 0;
        }
        // Se transfiere el monto total de la segunda puja más baja multiplicado por la cantidad de ganadores al propietario
        owner.transfer(pujaSegunda * ganadores.length);
        // Se emite el evento de finalización de la subasta
        emit SubastaFinalizada(ganadoresArray, montosArray);
    }

    // Función para reclamar el premio por parte de los ganadores
    function reclamarPremio() public {
        // Se verifica que se haya superado la fecha de finalización
        require(block.timestamp >= endDate, "La subasta aún no ha finalizado");
        // Se verifica que el participante sea un ganador de la subasta
        require(fianzas[msg.sender] > 0, "No eres un ganador de la subasta");
        // Se transfiere la fianza del participante (que es el premio) a su dirección
        uint256 premio = fianzas[msg.sender];
        // Se establece la fianza del participante en 0
        fianzas[msg.sender] = 0;
        payable(msg.sender).transfer(premio);
    }
}