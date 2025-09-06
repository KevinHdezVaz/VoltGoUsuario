import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'VoltGo',
      'searchingTechnician': 'Searching for technician',
      'technicianArriving': 'Technician arriving in',
      'minutes': 'minutes',
      'estimated': 'Estimated',
      'arrival': 'Arrival',
      'connector': 'Connector',
      'estimatedTime': 'Estimated time',
      'estimatedCost': 'Estimated cost',
      'cancelSearch': 'Cancel search',
      'technicianConfirmed': 'Technician confirmed',
      'serviceInProgress': 'Service in progress',
      'chargingVehicle': 'Charging your vehicle',
      'requestCharge': 'Request Charge',
      'viewActiveService': 'View Active Service',
      'youHaveActiveService': 'You have an active service',
      'tapToFindTechnician': 'Tap to find a technician',
      'cancel': 'Cancel',
      'cancelService': 'Cancel Service',
      'followRealTime': 'Follow in real time',
      'serviceCompleted': 'Service Completed!',
      'howWasExperience': 'How was your experience?',
      'addComment': 'Add comment (optional)',
      'skip': 'Skip',
      'send': 'Send',
      'locationRequired': 'Location Required',
      'locationNeeded':
          'To request a service we need access to your location. Please enable location services.',
      'activate': 'Activate',
      'permissionDenied': 'Permission Denied',
      'cannotContinue':
          'We cannot continue without access to your location. Please grant the necessary permissions in the app settings.',
      'goToSettings': 'Go to Settings',
      'vehicleRegistration': 'Vehicle Registration',
      'vehicleNeeded':
          'To use VoltGo you need to register your electric vehicle.',
      'whyNeeded': 'Why is it necessary?',
      'whyNeededDetails': '• Identify the required connector type\n'
          '• Calculate accurate charging times\n'
          '• Assign specialized technicians\n'
          '• Provide the best personalized service',
      'registerVehicle': 'Register Vehicle',
      'activeService': 'Active Service',
      'youHaveActiveServiceDialog': 'You already have an active service:',
      'request': 'Request',
      'status': 'Status',
      'requested': 'Requested',
      'whatToDo': 'What would you like to do?',
      'viewService': 'View Service',
      'timeExpired': 'Time Expired',
      'cannotCancelNow': 'It is no longer possible to cancel this service.',
      'technicianOnWay':
          'The technician is already on the way to your location. Please wait for their arrival.',
      'understood': 'Understood',
      'cancellationFee': 'Cancellation fee',
      'feeApplied':
          'A fee of \${fee} will be applied because the technician was already assigned to the service.',
      'technicianAssigned': 'Technician Assigned!',
      'technicianAccepted':
          'A technician has accepted your request and is on the way.',
      'seeProgress': 'You can see the technician\'s progress on the map.',
      'serviceExpired': 'Service Expired',
      'serviceAutoCancelled': 'Your service has been automatically cancelled.',
      'timeLimitExceeded': 'Time limit exceeded',
      'serviceActiveHour':
          'The service has been active for more than 1 hour without being completed. For your protection, we have automatically cancelled it.',
      'noChargesApplied': 'No charges applied',
      'requestNew': 'Request New',
      'technicianCancelled': 'Technician Cancelled',
      'technicianHasCancelled': 'The technician has cancelled the service.',
      'dontWorry': 'Don\'t worry',
      'technicianCancellationReason':
          'This can happen due to emergencies or technical issues. No charges will be applied to you.',
      'nextStep': 'Next step',
      'requestImmediately':
          'You can request a new service immediately. We will connect you with another available technician.',
      'findAnotherTechnician': 'Find Another Technician',
      'timeWarning': 'Time Warning',
      'serviceWillExpire': 'The service will expire in',
      'viewDetails': 'View Details',
      'finalWarning': 'Final Warning!',
      'serviceExpireMinutes':
          'Your service will expire in {minutes} minutes and will be automatically cancelled.',
      'contactTechnician': 'Contact Technician',
      'timeDetails': 'Time Details',
      'timeRemaining': 'Time remaining',
      'systemInfo': 'System information',
      'serviceInfo': '• Services are automatically cancelled after 1 hour\n'
          '• This protects both the customer and the technician\n'
          '• No charges are applied for automatic cancellations\n'
          '• You can request a new service immediately',

      // Additional strings used in PassengerMapScreen
      'chatWithTechnician': 'Chat with technician',
      'cancellationTimeExpired': 'Cancellation time expired',
      'serviceCancelled': 'Service Cancelled',
      'serviceCancelledSuccessfully':
          'Your service has been cancelled successfully.',
      'preparingEquipment': 'Preparing charging equipment',
      'technicianOnSite': 'Technician on site',
      'equipmentStatus': 'Equipment status',
      'preparingCharge': 'Preparing charge',
      'notCancellable': 'Not cancellable',
      'timeToCancel': 'Time to cancel:',
      'lastMinute': 'Last minute!',
      'minutesRemaining': 'minutes remaining',
      'findingBestTechnician': 'Finding the best technician for you',
      'thankYouForUsingVoltGo': 'Thank you for using VoltGo',
      'total': 'Total',
      'close': 'Close',

  // Nuevas claves para Google Sign In y Complete Profile
  'welcomeBack': 'Welcome back',
  'signInWithGoogle': 'Sign in with Google',
  'completeYourProfile': 'Complete your profile',
  'addPhoneToCompleteRegistration': 'Add your phone number to complete registration',
  'registeredData': 'Registered data',
  'completeProfile': 'Complete profile',
  'skipForNow': 'Skip for now',
  'profileCompleted': 'Profile completed successfully',
  'phoneNumberWillBeUsedFor': 'Your number will be used for notifications and communication', 
      'technicianWorkingOnVehicle': 'The technician is working on your vehicle',
      'since': 'Since',
      'initial': 'Initial', 
      'time': 'Time',
      'technicianPreparingEquipment':
          'The technician is preparing the equipment. The service will start soon.',
      'viewTechnicianOnSite': 'View technician on site',
      'chat': 'Chat',
      'thankYouForRating': 'Thank you for your rating!',
      'processingRequest': 'Processing request...',
      'errorLoadingMap': 'Error loading map',
      'vehicleVerification': 'Vehicle Verification',
      'checkingVehicle': 'Checking your vehicle',
      'verifyingInformation': 'We are verifying your information...',
      'verificationNeeded': 'Verification Needed',
      'couldNotVerifyVehicle':
          'We could not verify if you have a registered vehicle. Please make sure you have a vehicle registered to continue.',
      'goToRegistration': 'Go to Registration',
      'syncInProgress': 'Synchronization in Progress',
      'vehicleRegisteredCorrectly':
          'Your vehicle was registered correctly, but the system is synchronizing the information.',
      'syncOptions': 'Options:',
      'syncOptionsText':
          '• Wait a few seconds and continue\n• Close and reopen the app\n• If it persists, contact support',
      'retry': 'Retry',
      'continueAnyway': 'Continue Anyway',
      'processing': 'Processing...',
      'nearbyTechnicians': 'Looking for nearby technicians',
      'thisCanTakeSeconds': 'This can take a few seconds',
      'searchingDots': 'Searching technicians nearby',
      'onSite': 'On site',
      'cancelled': 'Cancelled',
      'unknownStatus': 'Unknown status',
      'fewSecondsAgo': 'A few seconds ago',
      'minutesAgo': 'minutes ago',
      'hoursAgo': 'hours ago',
      'daysAgo': 'days ago',
      'ago': 'ago',
      'serviceVehicle': 'Service vehicle',
      'notSpecified': 'Not specified',
      'technician': 'Technician',
      'errorCancellingService': 'Error cancelling service',
      'noActiveServiceToCancel': 'No active service to cancel',
      'timeElapsedMinutes': 'minutes elapsed',
      'limitMinutes': 'limit minutes',
      'cannotCancelServiceNow': 'Cannot cancel service now',
      'technicianAlreadyOnWay':
          'The technician is already on the way to your location. Please wait for their arrival.',
      'serviceCancelledWithFee': 'Service cancelled with fee',
      'serviceCancelledSuccessfullyMessage': 'Service cancelled successfully',
      'no': 'No',
      'yes': 'Yes',
      'yesCancel': 'Yes, cancel',
      'areYouSureCancelService': 'Are you sure you want to cancel the service?',
      'cancelRide': 'Cancel Service',
      'blockedFromCancelling': 'Blocked from cancelling',
      'timeForCancellingExpired': 'Time for cancelling expired',
      'serviceHasExceededTimeLimit': 'Service has exceeded the time limit',
      'serviceActiveMinutes':
          'The service has been active for {minutes} minutes. You can cancel it without charges.',
      'cancelExpiredService': 'Cancel Expired Service',
      'forceExpireService': 'Force Expire Service',
      'areYouSureCancelExpiredService':
          'Are you sure you want to cancel this service?',
      'serviceInformation': 'Service information:',
      'timeElapsed': 'Time elapsed',
      'currentStatus': 'Current status',
      'noChargesForCancellation': 'No charges will be applied for cancellation',
      'canRequestNewServiceImmediately':
          'You can request a new service immediately',
      'yesCancelService': 'Yes, Cancel Service',
      'serviceExpiredAutomatically': 'Service expired automatically',
      'serviceActiveForHourWithoutCompletion':
          'The service has been active for more than 1 hour without being completed. For your protection, we have automatically cancelled it.',
      'noChargesAppliedForExpiredService':
          'No charges applied for expired service',
      'canRequestNewService': 'You can request a new service when you like',
      'requestNewService': 'Request New Service',
      'searchForAnotherTechnician': 'Search for Another Technician',
      'emergenciesOrTechnicalIssues':
          'This can happen due to emergencies or technical issues. No charges will be applied.',
      'canRequestNewServiceNow':
          'You can request a new service immediately. We will connect you with another available technician.',
      'ifTechnicianHasNotArrived':
          'If the technician has not arrived yet, you can contact them or wait for the system to cancel automatically at no cost.',
      'serviceDetailsInfo': 'Service Details Info',
      'serviceDetailsText':
          'Time remaining: {minutes} minutes\n\n📋 System information:\n• Services are automatically cancelled after 1 hour\n• This protects both the customer and the technician\n• No charges are applied for automatic cancellations\n• You can request a new service immediately',
      'technicianHasArrived': 'Technician has arrived!',
      'technicianAtLocationPreparingEquipment':
          'The technician is at your location preparing the charging equipment.',
      'serviceStarted': '⚡ Service Started',
      'technicianStartedChargingVehicle':
          'The technician has started charging your electric vehicle.',
      'serviceCompletedSuccessfully': '✅ Service Completed',
      'vehicleChargedSuccessfully':
          'Your vehicle has been charged successfully! Thank you for using VoltGo.',
      'statusUpdated': 'Status Updated',
      'serviceStatusChanged': 'Your service status has changed.',
      'technicianConfirmedTitle': 'Technician Confirmed!',
      'technicianConfirmedMessage':
          'A professional technician has accepted your request and is getting ready.',
      'technicianEnRoute': 'Technician on Route',
      'technicianHeadingToLocation':
          'The technician is heading to your location. You can follow their progress on the map.',
      'technicianArrivedTitle': 'Technician has Arrived!',
      'technicianArrivedMessage':
          'The technician is at your location preparing the charging equipment.',
      'serviceInitiatedTitle': '⚡ Service Initiated',
      'serviceInitiatedMessage':
          'The technician has started charging your electric vehicle.',
      'serviceCompletedTitle': '✅ Service Completed',
      'serviceCompletedMessage':
          'Your vehicle has been charged successfully! Thank you for using VoltGo.',
      'technicianWillDocumentProgress':
          'The technician will document the progress during the service',
      'serviceProgress': 'Service Progress',
      'from': 'From',
      'batteryLevel': 'Battery level',
      'chargingTime': 'Charging time',
      'min': 'min',
      'followInRealTime': 'Follow in real time',
      'averageRating': 'Average rating',
      'phoneCall': 'Phone call',
      'sendMessage': 'Send message',
      'message': 'Message',
      'equipmentReady': 'Equipment ready',
      'startingCharge': 'Starting charge',
      'connectingTechnician': 'Connecting to technician',
      'thankYouForYourRating': 'Thank you for your rating!',
      'serviceUpdatedCorrectly': 'Service updated correctly',
      'errorRefreshingServiceData': 'Error refreshing service data',
      'noActiveService': 'No active service',
      'couldNotGetLocation': 'Could not get your location',
      'errorRequestingService': 'Error requesting service',
      'noTechniciansAvailable':
          'No technicians available in your area at this time.',
      'needToRegisterVehicle':
          'You need to register a vehicle to request the service.',
      'authorizationError': 'Authorization error. Please log in again.',
      'sessionExpired': 'Session expired. Please log in again.',
      'settings': 'Settings',
      'logout': 'Logout',
      'logoutConfirmationMessage': 'Are you sure you want to logout?',
      'loggingOut': 'Logging out...',
      'logoutError': 'Error logging out. Please try again.',
      'pleaseWait': 'Please wait...',
      'pleaseWaitMoment': 'Please wait a moment',
      'error': 'Error',
      'couldNotLoadProfile': 'Could not load profile',
      'account': 'Account',
      'editProfile': 'Edit Profile',
      'securityAndPassword': 'Security and Password',
      'chatHistory': 'Chat History',
      'paymentMethods': 'Payment Methods',
      'vehicle': 'Vehicle',
      'manageVehicles': 'Manage Vehicles',
      'documents': 'Documents',
      'serviceHistory': 'Service History',
      'reviewPreviousServices': 'Review your previous services',
      'all': 'All',
      'completed': 'Completed',
       'pending': 'Pending',
      'accepted': 'Accepted',
      'enRoute': 'En Route',
       'charging': 'Charging',
      'today': 'Today',
      'yesterday': 'Yesterday',
       'errorLoadingHistory': 'Error loading history',
       'noServicesInHistory': 'You have no services in your history.',
      'requestService': 'Request Service',

      'createAccount': 'Create Your Account',
      'completeFormToStart': 'Complete the form to get started.',
      'fullName': 'Full Name',
      'yourNameAndSurname': 'Your name and surname',
      'emailHint': 'yourmail@example.com',
      'mobilePhone': 'Mobile Phone',
      'phoneNumber': 'Phone number',
      'confirmPassword': 'Confirm Password',
      'minimumCharacters': 'Minimum 8 characters',
      'signUpWithGoogle': 'Sign up with Google',
      'signUpWithApple': 'Sign up with Apple',
      'welcomeSuccessfulRegistration': 'Welcome! Successful registration.',
      'errorOccurred': 'An error occurred',
      'alreadyHaveAccount': 'Already have an account? ',
      'signInHere': 'Sign in here.',
// En inglés:
      'registerElectricVehicle': 'Register Your Electric Vehicle',
      'step': 'Step',
      'of': 'of',
      'vehicleInformation': 'Vehicle Information',
      'brand': 'Brand',
      'model': 'Model',
      'year': 'Year',
        
  'orRegisterWithEmail': 'Or register with your email',

      'identification': 'Identification',
      'plate': 'Plate',
      'color': 'Color',
      'technicalSpecs': 'Technical Specifications',
      'connectorType': 'Connector Type',
      'other': 'Other',
      'white': 'White',
      'black': 'Black',
      'gray': 'Gray',
      'silver': 'Silver',
      'red': 'Red',
      'blue': 'Blue',
      'green': 'Green',
      'writeBrandHint': 'Write a brand if it\'s not in the list',
      'selectOrEnterBrand': 'Please select or enter a brand',
      'modelHint': 'Ex: Model 3, Leaf, ID.4',
      'plateHint': 'ABC-123',
      'specifyColor': 'Specify the color',
      'colorHint': 'Ex: Gold, Purple',
      'enterColor': 'Enter a color',
      'vehicleRegistrationError': 'Error registering vehicle',
      'vehicleRegistered': 'Vehicle Registered!',
      'vehicleRegisteredSuccess':
          'Your vehicle has been registered successfully.',
      'continueText': 'Continue',
      'selectBrandMessage': 'Please select a brand',
      'enterModelMessage': 'Please enter the model',
      'enterYearMessage': 'Please enter the year',
      'validYearMessage': 'Please enter a valid year',
      'enterPlateMessage': 'Please enter the plate',
      'selectColorMessage': 'Please select a color',
      'specifyColorMessage': 'Please specify the color',
      'selectConnectorMessage': 'Please select the connector type',
      'completeRequiredFields': 'Please complete all required fields',
      'fieldRequired': 'This field is required',
      'numbersOnly': 'Enter numbers only',
      'yearRange': 'Year must be between',
      'and': 'and',
      'plateMinLength': 'Plate must have at least 3 characters',
      'previous': 'Previous',
      'next': 'Next',
      'register': 'Register',
      'welcomeUser': 'Welcome User',
      'email': 'Email',
      'enterEmail': 'Enter your email address.',
      'password': 'Password',
      'enterPassword': 'Efnter your password',
      'signIn': 'Sign In',
      'incorrectUserPassword': 'Incorrect username or password',
      'serverConnectionError': 'Server connection error',
      'or': 'OR',
      'signInWithGoogle': 'Sign in with Google',
      'signInWithApple': 'Sign in with Apple',
      'noAccount': 'Don\'t have an account? ',
      'createHere': 'Create one here.',
      'history': 'History',

      'onboardingTitle1': 'Emergency on the road?',
      'onboardingSubtitle1':
          'Request a technician and follow their journey in real time',
      'onboardingTitle2': 'Trained and verified professionals.',
      'onboardingSubtitle2':
          'We have trained personnel for your type of vehicle and with certifications.',
      'onboardingTitle3': 'Notifications',
      'onboardingSubtitle3':
          'Stay informed about promotions, events and relevant app news.',
    },
    'es': {
      'onboardingTitle2': 'Profesionales capacitados y verificados.',
      'onboardingSubtitle2':
          'Contamos con personal capacitado para tu tipo de vehículo y con certificaciones.',
      'onboardingTitle3': 'Notificaciones',
      'onboardingSubtitle3':
          'Infórmate sobre promociones, eventos y noticias relevantes de la app.',

      'appTitle': 'VoltGo',
      'searchingTechnician': 'Buscando técnico',
      'technicianArriving': 'Técnico llegando en',
      'minutes': 'minutos',
      'estimated': 'Estimado',
      'history': 'Historial',

      'arrival': 'Llegada',
      'connector': 'Conector',
      'estimatedTime': 'Tiempo estimado',
      'estimatedCost': 'Costo estimado',
      'cancelSearch': 'Cancelar búsqueda',
      'technicianConfirmed': 'Técnico confirmado',
      'serviceInProgress': 'Servicio en progreso',
      'chargingVehicle': 'Cargando tu vehículo',
      'requestCharge': 'Solicitar Carga',
      'viewActiveService': 'Ver Servicio Activo',
      'youHaveActiveService': 'Tienes un servicio en curso',
      'tapToFindTechnician': 'Toca para buscar un técnico',
      'cancel': 'Cancelar',
      'cancelService': 'Cancelar Servicio',
      'followRealTime': 'Seguir en tiempo real',
      'serviceCompleted': '¡Servicio Completado!',
      'howWasExperience': '¿Cómo fue tu experiencia?',
      'addComment': 'Agregar comentario (opcional)',
      'skip': 'Omitir',
      'send': 'Enviar',
      'locationRequired': 'Ubicación Necesaria',
      'locationNeeded':
          'Para solicitar un servicio necesitamos acceder a tu ubicación. Por favor, activa los servicios de ubicación.',
      'activate': 'Activar',
      'permissionDenied': 'Permiso Denegado',
      'cannotContinue':
          'No podemos continuar sin acceso a tu ubicación. Por favor, otorga los permisos necesarios en la configuración de la aplicación.',
      'goToSettings': 'Ir a Configuración',
      'vehicleRegistration': 'Registra tu Vehículo',
      'vehicleNeeded':
          'Para utilizar VoltGo necesitas registrar tu vehículo eléctrico.',
      'whyNeeded': '¿Por qué es necesario?',
      'whyNeededDetails': '• Identificar el tipo de conector necesario\n'
          '• Calcular tiempos de carga precisos\n'
          '• Asignar técnicos especializados\n'
          '• Brindar el mejor servicio personalizado',
      'registerVehicle': 'Registrar Vehículo',
      'completeYourProfile': 'Completa tu perfil',
'addPhoneToCompleteRegistration': 'Agrega tu número de teléfono para completar el registro',
'registeredData': 'Datos registrados',
'completeProfile': 'Completar perfil',
'skipForNow': 'Omitir por ahora',
'profileCompleted': 'Perfil completado exitosamente',
'phoneNumberWillBeUsedFor': 'Tu número será usado para notificaciones y comunicación',
      'activeService': 'Servicio Activo',
      'youHaveActiveServiceDialog': 'Ya tienes un servicio en curso:',
      'request': 'Solicitud',
      'status': 'Estado',
      'requested': 'Solicitado',
      'whatToDo': '¿Qué deseas hacer?',
        'orRegisterWithEmail': 'O regístrate con tu email',

      'viewService': 'Ver Servicio',
      'timeExpired': 'Tiempo Expirado',
      'cannotCancelNow': 'Ya no es posible cancelar este servicio.',
      'technicianOnWay':
          'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
      'understood': 'Entendido',
      'cancellationFee': 'Tarifa de cancelación',
      'feeApplied':
          'Se aplicará una tarifa de \${fee} debido a que el técnico ya estaba asignado al servicio.',
      'technicianAssigned': '¡Técnico asignado!',
      'technicianAccepted':
          'Un técnico ha aceptado tu solicitud y está en camino.',
      'seeProgress': 'Puedes ver el progreso del técnico en el mapa.',
      'serviceExpired': 'Servicio Expirado',
      'serviceAutoCancelled': 'Tu servicio ha sido cancelado automáticamente.',
      'timeLimitExceeded': 'Tiempo límite excedido',
      'serviceActiveHour':
          'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
      'noChargesApplied': 'Sin cargos aplicados',
      'requestNew': 'Solicitar Nuevo',
      'technicianCancelled': 'Técnico Canceló',
      'technicianHasCancelled': 'El técnico ha cancelado el servicio.',
      'dontWorry': 'No te preocupes',
      'technicianCancellationReason':
          'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
      'nextStep': 'Siguiente paso',
      'requestImmediately':
          'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
      'findAnotherTechnician': 'Buscar Otro Técnico',
      'timeWarning': 'Advertencia de Tiempo',
      'serviceWillExpire': 'El servicio expirará en',
      'viewDetails': 'Ver Detalles',
      'finalWarning': '¡Último Aviso!',
      'serviceExpireMinutes':
          'Tu servicio expirará en {minutes} minutos y será cancelado automáticamente.',
      'contactTechnician': 'Contactar Técnico',
      'timeDetails': 'Detalles del Tiempo',
      'timeRemaining': 'Tiempo restante',
      'systemInfo': 'Información del sistema',
      'serviceInfo':
          '• Los servicios se cancelan automáticamente después de 1 hora\n'
              '• Esto protege tanto al cliente como al técnico\n'
              '• No se aplican cargos por cancelaciones automáticas\n'
              '• Puedes solicitar un nuevo servicio inmediatamente',

      // Additional strings used in PassengerMapScreen
      'chatWithTechnician': 'Chat con técnico',
      'cancellationTimeExpired': 'Tiempo de cancelación agotado',
      'serviceCancelled': 'Servicio Cancelado',
      'serviceCancelledSuccessfully':
          'Tu servicio ha sido cancelado exitosamente.',
      'preparingEquipment': 'Preparando equipo de carga',
      'technicianOnSite': 'Técnico en sitio',
      'equipmentStatus': 'Estado del equipo',
      'preparingCharge': 'Preparando carga',
      'notCancellable': 'No cancelable',
      'timeToCancel': 'Tiempo para cancelar:',
      'lastMinute': '¡Último minuto!',
      'minutesRemaining': 'minutos restantes',
      'findingBestTechnician': 'Buscando el mejor técnico para ti',
      'thankYouForUsingVoltGo': 'Gracias por usar VoltGo',
      'total': 'Total',
      'close': 'Cerrar',
      'technicianWorkingOnVehicle': 'El técnico está trabajando en tu vehículo',
      'since': 'Desde',
      'initial': 'Inicial',
      'time': 'Tiempo',
      'technicianPreparingEquipment':
          'El técnico está preparando el equipo. El servicio comenzará pronto.',
      'viewTechnicianOnSite': 'Ver técnico en sitio',
      'chat': 'Chat',
      'thankYouForRating': '¡Gracias por tu calificación!',
      'processingRequest': 'Procesando solicitud...',
      'errorLoadingMap': 'Error al cargar el mapa',
      'vehicleVerification': 'Verificación de Vehículo',
      'checkingVehicle': 'Verificando tu vehículo',
      'verifyingInformation': 'Estamos verificando tu información...',
      'verificationNeeded': 'Verificación Necesaria',
      'couldNotVerifyVehicle':
          'No pudimos verificar si tienes un vehículo registrado. Por favor, asegúrate de tener un vehículo registrado para continuar.',
      'goToRegistration': 'Ir a Registro',
      'syncInProgress': 'Sincronización en Proceso',
      'vehicleRegisteredCorrectly':
          'Tu vehículo se registró correctamente, pero el sistema está sincronizando la información.',
      'syncOptions': 'Opciones:',
      'syncOptionsText':
          '• Espera unos segundos y continúa\n• Cierra y vuelve a abrir la app\n• Si persiste, contacta soporte',
      'retry': 'Reintentar',
      'continueAnyway': 'Continuar de Todas Formas',
      'processing': 'Procesando...',
      'nearbyTechnicians': 'Buscando técnicos cercanos',
      'thisCanTakeSeconds': 'Esto puede tomar unos segundos',
      'searchingDots': 'Buscando técnicos cercanos',
      'onSite': 'En sitio',
      'cancelled': 'Cancelado',
      'unknownStatus': 'Estado desconocido',
      'fewSecondsAgo': 'Hace unos segundos',
      'minutesAgo': 'minutos atrás',
      'hoursAgo': 'horas atrás',
      'daysAgo': 'días atrás',
      'ago': 'hace',
      'serviceVehicle': 'Vehículo de servicio',
      'notSpecified': 'No especificado',
      'technician': 'Técnico',
      'errorCancellingService': 'Error al cancelar el servicio',
      'noActiveServiceToCancel': 'No hay servicio activo para cancelar',
      'timeElapsedMinutes': 'minutos transcurridos',
      'limitMinutes': 'minutos límite',
      'cannotCancelServiceNow': 'No se puede cancelar el servicio ahora',
      'technicianAlreadyOnWay':
          'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
      'serviceCancelledWithFee': 'Servicio cancelado con tarifa',
      'serviceCancelledSuccessfullyMessage': 'Servicio cancelado exitosamente',
      'no': 'No',
      'yes': 'Sí',
      'yesCancel': 'Sí, cancelar',
      'areYouSureCancelService':
          '¿Estás seguro de que deseas cancelar el servicio?',
      'cancelRide': 'Cancelar Servicio',
      'blockedFromCancelling': 'No cancelable',
      'timeForCancellingExpired': 'Tiempo de cancelación agotado',
      'serviceHasExceededTimeLimit': 'Servicio ha excedido el tiempo límite',
      'serviceActiveMinutes':
          'El servicio lleva {minutes} minutos activo. Puedes cancelarlo sin cargos.',
      'cancelExpiredService': 'Cancelar Servicio Expirado',
      'forceExpireService': 'Forzar Expiración del Servicio',
      'areYouSureCancelExpiredService':
          '¿Estás seguro de que deseas cancelar este servicio?',
      'serviceInformation': 'Información del servicio:',
      'timeElapsed': 'Tiempo transcurrido',
      'currentStatus': 'Estado actual',
      'noChargesForCancellation': 'No se aplicarán cargos por cancelación',
      'canRequestNewServiceImmediately':
          'Podrás solicitar un nuevo servicio inmediatamente',
      'yesCancelService': 'Sí, Cancelar Servicio',
      'serviceExpiredAutomatically': 'Servicio expirado automáticamente',
      'serviceActiveForHourWithoutCompletion':
          'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
      'noChargesAppliedForExpiredService':
          'Sin cargos aplicados por servicio expirado',
      'canRequestNewService':
          'Puedes solicitar un nuevo servicio cuando gustes',
      'requestNewService': 'Solicitar Nuevo Servicio',
      'searchForAnotherTechnician': 'Buscar Otro Técnico',
      'emergenciesOrTechnicalIssues':
          'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
      'canRequestNewServiceNow':
          'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
      'ifTechnicianHasNotArrived':
          'Si el técnico no ha llegado aún, puedes contactarlo o esperar a que el sistema cancele automáticamente sin costo.',
      'serviceDetailsInfo': 'Detalles del Servicio',
      'serviceDetailsText':
          'Tiempo restante: {minutes} minutos\n\n📋 Información del sistema:\n• Los servicios se cancelan automáticamente después de 1 hora\n• Esto protege tanto al cliente como al técnico\n• No se aplican cargos por cancelaciones automáticas\n• Puedes solicitar un nuevo servicio inmediatamente',
      'technicianHasArrived': '¡Técnico ha llegado!',
      'technicianAtLocationPreparingEquipment':
          'El técnico está en tu ubicación preparando el equipo de carga.',
      'serviceStarted': '⚡ Servicio Iniciado',
      'technicianStartedChargingVehicle':
          'El técnico ha comenzado la carga de tu vehículo eléctrico.',
      'serviceCompletedSuccessfully': '✅ Servicio Completado',
      'vehicleChargedSuccessfully':
          '¡Tu vehículo ha sido cargado exitosamente! Gracias por usar VoltGo.',
      'statusUpdated': 'Estado Actualizado',
      'serviceStatusChanged': 'El estado de tu servicio ha cambiado.',
      'technicianConfirmedTitle': '¡Técnico Confirmado!',
      'technicianConfirmedMessage':
          'Un técnico profesional ha aceptado tu solicitud y se está preparando.',
      'technicianEnRoute': 'Técnico en Camino',
      'technicianHeadingToLocation':
          'El técnico se dirige hacia tu ubicación. Puedes seguir su progreso en el mapa.',
      'technicianArrivedTitle': '¡Técnico ha Llegado!',
      'technicianArrivedMessage':
          'El técnico está en tu ubicación preparando el equipo de carga.',
      'serviceInitiatedTitle': '⚡ Servicio Iniciado',
      'serviceInitiatedMessage':
          'El técnico ha comenzado la carga de tu vehículo eléctrico.',
      'serviceCompletedTitle': '✅ Servicio Completado',
      'serviceCompletedMessage':
          '¡Tu vehículo ha sido cargado exitosamente! Gracias por usar VoltGo.',
      'technicianWillDocumentProgress':
          'El técnico documentará el progreso durante el servicio',
      'serviceProgress': 'Progreso del Servicio',
      'from': 'Desde',
      'batteryLevel': 'Nivel de batería',
      'chargingTime': 'Tiempo de carga',
      'min': 'min',
      'followInRealTime': 'Seguir en tiempo real',
      'averageRating': 'Calificación promedio',
      'phoneCall': 'Llamada telefónica',
      'sendMessage': 'Enviar mensaje',
      'message': 'Mensaje',
      'equipmentReady': 'Equipo listo',
      'startingCharge': 'Iniciando carga',
      'connectingTechnician': 'Conectando con técnico',
      'thankYouForYourRating': '¡Gracias por tu calificación!',
      'serviceUpdatedCorrectly': 'Servicio actualizado correctamente',
      'errorRefreshingServiceData': 'Error actualizando datos del servicio',
      'noActiveService': 'Sin servicio activo',
      'couldNotGetLocation': 'No se pudo obtener tu ubicación',
      'errorRequestingService': 'Error al solicitar el servicio',
      'noTechniciansAvailable':
          'No hay técnicos disponibles en tu área en este momento.',
      'needToRegisterVehicle':
          'Necesitas registrar un vehículo para solicitar el servicio.',
      'authorizationError':
          'Error de autorización. Por favor, inicia sesión nuevamente.',
      'sessionExpired': 'Sesión expirada. Por favor, inicia sesión nuevamente.',

// En español:
      'settings': 'Ajustes',
   'welcomeBack': 'Bienvenido de vuelta',
  'signInWithGoogle': 'Iniciar sesión con Google', 
      'logout': 'Cerrar Sesión',
      'logoutConfirmationMessage':
          '¿Estás seguro de que quieres cerrar sesión?',
      'loggingOut': 'Cerrando sesión...',
      'logoutError': 'Error al cerrar sesión. Inténtalo nuevamente.',
      'pleaseWait': 'Por favor espera...',
      'pleaseWaitMoment': 'Por favor espera un momento',
      'error': 'Error',
      'couldNotLoadProfile': 'No se pudo cargar el perfil',
      'account': 'Cuenta',
      'editProfile': 'Editar Perfil',
      'securityAndPassword': 'Seguridad y Contraseña',
      'chatHistory': 'Historial de Chats',
      'paymentMethods': 'Métodos de Pago',
      'vehicle': 'Vehículo',
      'manageVehicles': 'Gestionar Vehículos',
      'documents': 'Documentos',
      'serviceHistory': 'Historial de Servicios',
      'reviewPreviousServices': 'Revisa tus servicios anteriores',
      'all': 'Todo',
      'completed': 'Completado',
       'pending': 'Pendiente',
      'accepted': 'Aceptado',
      'enRoute': 'En Camino',
       'charging': 'Cargando',
      'today': 'Hoy',
      'yesterday': 'Ayer',
       'errorLoadingHistory': 'Error al cargar el historial',
       'noServicesInHistory': 'No tienes servicios en tu historial.',
      'requestService': 'Solicitar Servicio',

// En español:
      'registerElectricVehicle': 'Registra tu Vehículo Eléctrico',
      'step': 'Paso',
      'of': 'de',
      'vehicleInformation': 'Información del Vehículo',
      'brand': 'Marca',
      'model': 'Modelo',
      'year': 'Año',
      'identification': 'Identificación',
      'plate': 'Placa',
      'color': 'Color',
      'technicalSpecs': 'Especificaciones Técnicas',
      'connectorType': 'Tipo de Conector',
      'other': 'Otro',
      'white': 'Blanco',
      'black': 'Negro',
      'gray': 'Gris',
      'silver': 'Plata',
      'red': 'Rojo',
      'blue': 'Azul',
      'green': 'Verde',
      'writeBrandHint': 'Escribe una marca si no está en la lista',
      'selectOrEnterBrand': 'Por favor, selecciona o ingresa una marca',
      'modelHint': 'Ej: Model 3, Leaf, ID.4',
      'plateHint': 'ABC-123',
      'specifyColor': 'Especifica el color',
      'colorHint': 'Ej: Dorado, Morado',
      'enterColor': 'Ingresa un color',
      'vehicleRegistrationError': 'Error al registrar el vehículo',
      'vehicleRegistered': '¡Vehículo Registrado!',
      'vehicleRegisteredSuccess':
          'Tu vehículo ha sido registrado exitosamente.',
      'continueText': 'Continuar',
      'selectBrandMessage': 'Por favor selecciona una marca',
      'enterModelMessage': 'Por favor ingresa el modelo',
      'enterYearMessage': 'Por favor ingresa el año',
      'validYearMessage': 'Por favor ingresa un año válido',
      'enterPlateMessage': 'Por favor ingresa la placa',
      'selectColorMessage': 'Por favor selecciona un color',
      'specifyColorMessage': 'Por favor especifica el color',
      'selectConnectorMessage': 'Por favor selecciona el tipo de conector',
      'completeRequiredFields':
          'Por favor completa todos los campos requeridos',
      'fieldRequired': 'Este campo es requerido',
      'numbersOnly': 'Ingresa solo números',
      'yearRange': 'El año debe estar entre',
      'and': 'y',
      'plateMinLength': 'La placa debe tener al menos 3 caracteres',
      'previous': 'Anterior',
      'next': 'Siguiente',
      'welcomeUser': 'Bienvenido Usuario',
      'email': 'Correo electrónico',
      'enterEmail': 'Ingresa tu correo electrónico.',
      'password': 'Contraseña',
      'enterPassword': 'Ingresa tu contraseña',
      'signIn': 'Iniciar sesión',
      'incorrectUserPassword': 'Usuario o contraseña incorrectos',
      'serverConnectionError': 'Error de conexión con el servidor',
      'or': 'O',
      'signInWithGoogle': 'Iniciar sesión con Google',
      'signInWithApple': 'Iniciar sesión con Apple',
      'noAccount': '¿No tienes una cuenta? ',
      'createHere': 'Créala aquí.',
      'createAccount': 'Crea tu cuenta',
      'completeFormToStart': 'Completa el formulario para empezar.',
      'fullName': 'Nombre completo',
      'yourNameAndSurname': 'Tu nombre y apellido',
      'emailHint': 'tucorreo@ejemplo.com',
      'mobilePhone': 'Teléfono móvil',
      'phoneNumber': 'Número de teléfono',
      'confirmPassword': 'Confirmar contraseña',
      'minimumCharacters': 'Mínimo 8 caracteres',
      'signUpWithGoogle': 'Registrarse con Google',
      'signUpWithApple': 'Registrarse con Apple',
      'welcomeSuccessfulRegistration': '¡Bienvenido! Registro exitoso.',
      'errorOccurred': 'Ocurrió un error',
      'alreadyHaveAccount': '¿Ya tienes una cuenta? ',
      'signInHere': 'Inicia sesión.',
      'register': 'Registrar',
      'onboardingTitle1': '¿Emergencia en el camino?',
      'onboardingSubtitle1':
          'Solicita un técnico y sigue su trayecto en tiempo real',
    }
  };

  String get onboardingTitle2 =>
      _localizedValues[locale.languageCode]!['onboardingTitle2']!;
  String get onboardingSubtitle2 =>
      _localizedValues[locale.languageCode]!['onboardingSubtitle2']!;
  String get onboardingTitle3 =>
      _localizedValues[locale.languageCode]!['onboardingTitle3']!;
  String get onboardingSubtitle3 =>
      _localizedValues[locale.languageCode]!['onboardingSubtitle3']!;

// GETTERS NECESARIOS PARA AppLocalizations:
  String get createAccount =>
      _localizedValues[locale.languageCode]!['createAccount']!;
  String get completeFormToStart =>
      _localizedValues[locale.languageCode]!['completeFormToStart']!;
  String get fullName => _localizedValues[locale.languageCode]!['fullName']!;
  String get yourNameAndSurname =>
      _localizedValues[locale.languageCode]!['yourNameAndSurname']!;
  String get emailHint => _localizedValues[locale.languageCode]!['emailHint']!;
  String get mobilePhone =>
      _localizedValues[locale.languageCode]!['mobilePhone']!;
  String get phoneNumber =>
      _localizedValues[locale.languageCode]!['phoneNumber']!;
  String get confirmPassword =>
      _localizedValues[locale.languageCode]!['confirmPassword']!;
  String get minimumCharacters =>
      _localizedValues[locale.languageCode]!['minimumCharacters']!;
  String get signUpWithGoogle =>
      _localizedValues[locale.languageCode]!['signUpWithGoogle']!;
  String get signUpWithApple =>
      _localizedValues[locale.languageCode]!['signUpWithApple']!;
  String get welcomeSuccessfulRegistration =>
      _localizedValues[locale.languageCode]!['welcomeSuccessfulRegistration']!;
  String get errorOccurred =>
      _localizedValues[locale.languageCode]!['errorOccurred']!;
  String get alreadyHaveAccount =>
      _localizedValues[locale.languageCode]!['alreadyHaveAccount']!;
  String get signInHere =>
      _localizedValues[locale.languageCode]!['signInHere']!;
  String get welcomeUser =>
      _localizedValues[locale.languageCode]!['welcomeUser']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get enterEmail =>
      _localizedValues[locale.languageCode]!['enterEmail']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get enterPassword =>
      _localizedValues[locale.languageCode]!['enterPassword']!;
  String get signIn => _localizedValues[locale.languageCode]!['signIn']!;
  String get incorrectUserPassword =>
      _localizedValues[locale.languageCode]!['incorrectUserPassword']!;
  String get serverConnectionError =>
      _localizedValues[locale.languageCode]!['serverConnectionError']!;
  String get or => _localizedValues[locale.languageCode]!['or']!;
  String get signInWithGoogle =>
      _localizedValues[locale.languageCode]!['signInWithGoogle']!;
  String get signInWithApple =>
      _localizedValues[locale.languageCode]!['signInWithApple']!;
  String get noAccount => _localizedValues[locale.languageCode]!['noAccount']!;
  String get createHere =>
      _localizedValues[locale.languageCode]!['createHere']!;

  String get onboardingTitle1 =>
      _localizedValues[locale.languageCode]!['onboardingTitle1']!;
  String get onboardingSubtitle1 =>
      _localizedValues[locale.languageCode]!['onboardingSubtitle1']!;

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get searchingTechnician =>
      _localizedValues[locale.languageCode]!['searchingTechnician']!;
  String get technicianArriving =>
      _localizedValues[locale.languageCode]!['technicianArriving']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get estimated => _localizedValues[locale.languageCode]!['estimated']!;
  String get arrival => _localizedValues[locale.languageCode]!['arrival']!;
  String get connector => _localizedValues[locale.languageCode]!['connector']!;
  String get estimatedTime =>
      _localizedValues[locale.languageCode]!['estimatedTime']!;
  String get estimatedCost =>
      _localizedValues[locale.languageCode]!['estimatedCost']!;
  String get cancelSearch =>
      _localizedValues[locale.languageCode]!['cancelSearch']!;
  String get technicianConfirmed =>
      _localizedValues[locale.languageCode]!['technicianConfirmed']!;
  String get serviceInProgress =>
      _localizedValues[locale.languageCode]!['serviceInProgress']!;
  String get chargingVehicle =>
      _localizedValues[locale.languageCode]!['chargingVehicle']!;
  String get requestCharge =>
      _localizedValues[locale.languageCode]!['requestCharge']!;
  String get viewActiveService =>
      _localizedValues[locale.languageCode]!['viewActiveService']!;
  String get youHaveActiveService =>
      _localizedValues[locale.languageCode]!['youHaveActiveService']!;
  String get tapToFindTechnician =>
      _localizedValues[locale.languageCode]!['tapToFindTechnician']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get cancelService =>
      _localizedValues[locale.languageCode]!['cancelService']!;
  String get followRealTime =>
      _localizedValues[locale.languageCode]!['followRealTime']!;
  String get serviceCompleted =>
      _localizedValues[locale.languageCode]!['serviceCompleted']!;
  String get howWasExperience =>
      _localizedValues[locale.languageCode]!['howWasExperience']!;
  String get addComment =>
      _localizedValues[locale.languageCode]!['addComment']!;
  String get skip => _localizedValues[locale.languageCode]!['skip']!;
  String get send => _localizedValues[locale.languageCode]!['send']!;
  String get locationRequired =>
      _localizedValues[locale.languageCode]!['locationRequired']!;
  String get locationNeeded =>
      _localizedValues[locale.languageCode]!['locationNeeded']!;
  String get activate => _localizedValues[locale.languageCode]!['activate']!;
  String get permissionDenied =>
      _localizedValues[locale.languageCode]!['permissionDenied']!;
  String get cannotContinue =>
      _localizedValues[locale.languageCode]!['cannotContinue']!;
  String get goToSettings =>
      _localizedValues[locale.languageCode]!['goToSettings']!;
  String get vehicleRegistration =>
      _localizedValues[locale.languageCode]!['vehicleRegistration']!;
  String get vehicleNeeded =>
      _localizedValues[locale.languageCode]!['vehicleNeeded']!;
  String get whyNeeded => _localizedValues[locale.languageCode]!['whyNeeded']!;
  String get whyNeededDetails =>
      _localizedValues[locale.languageCode]!['whyNeededDetails']!;
  String get registerVehicle =>
      _localizedValues[locale.languageCode]!['registerVehicle']!;
  String get activeService =>
      _localizedValues[locale.languageCode]!['activeService']!;
  String get youHaveActiveServiceDialog =>
      _localizedValues[locale.languageCode]!['youHaveActiveServiceDialog']!;
  String get request => _localizedValues[locale.languageCode]!['request']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String get requested => _localizedValues[locale.languageCode]!['requested']!;
  String get whatToDo => _localizedValues[locale.languageCode]!['whatToDo']!;
  String get viewService =>
      _localizedValues[locale.languageCode]!['viewService']!;
  String get timeExpired =>
      _localizedValues[locale.languageCode]!['timeExpired']!;
  String get cannotCancelNow =>
      _localizedValues[locale.languageCode]!['cannotCancelNow']!;
  String get technicianOnWay =>
      _localizedValues[locale.languageCode]!['technicianOnWay']!;
  String get understood =>
      _localizedValues[locale.languageCode]!['understood']!;
  String cancellationFee(String fee) =>
      _localizedValues[locale.languageCode]!['cancellationFee']!
          .replaceAll('{fee}', fee);
  String feeApplied(String fee) =>
      _localizedValues[locale.languageCode]!['feeApplied']!
          .replaceAll('{fee}', fee);
  String get technicianAssigned =>
      _localizedValues[locale.languageCode]!['technicianAssigned']!;
  String get technicianAccepted =>
      _localizedValues[locale.languageCode]!['technicianAccepted']!;
  String get seeProgress =>
      _localizedValues[locale.languageCode]!['seeProgress']!;
  String get serviceExpired =>
      _localizedValues[locale.languageCode]!['serviceExpired']!;
  String get serviceAutoCancelled =>
      _localizedValues[locale.languageCode]!['serviceAutoCancelled']!;
  String get timeLimitExceeded =>
      _localizedValues[locale.languageCode]!['timeLimitExceeded']!;
  String get serviceActiveHour =>
      _localizedValues[locale.languageCode]!['serviceActiveHour']!;
  String get noChargesApplied =>
      _localizedValues[locale.languageCode]!['noChargesApplied']!;
  String get requestNew =>
      _localizedValues[locale.languageCode]!['requestNew']!;
  String get technicianCancelled =>
      _localizedValues[locale.languageCode]!['technicianCancelled']!;
  String get technicianHasCancelled =>
      _localizedValues[locale.languageCode]!['technicianHasCancelled']!;
  String get dontWorry => _localizedValues[locale.languageCode]!['dontWorry']!;
  String get technicianCancellationReason =>
      _localizedValues[locale.languageCode]!['technicianCancellationReason']!;
  String get nextStep => _localizedValues[locale.languageCode]!['nextStep']!;
  String get requestImmediately =>
      _localizedValues[locale.languageCode]!['requestImmediately']!;
  String get findAnotherTechnician =>
      _localizedValues[locale.languageCode]!['findAnotherTechnician']!;
  String get timeWarning =>
      _localizedValues[locale.languageCode]!['timeWarning']!;
  String get serviceWillExpire =>
      _localizedValues[locale.languageCode]!['serviceWillExpire']!;
  String get viewDetails =>
      _localizedValues[locale.languageCode]!['viewDetails']!;
  String get finalWarning =>
      _localizedValues[locale.languageCode]!['finalWarning']!;
  String serviceExpireMinutes(String minutes) =>
      _localizedValues[locale.languageCode]!['serviceExpireMinutes']!
          .replaceAll('{minutes}', minutes);
  String get contactTechnician =>
      _localizedValues[locale.languageCode]!['contactTechnician']!;
  String get timeDetails =>
      _localizedValues[locale.languageCode]!['timeDetails']!;
  String get timeRemaining =>
      _localizedValues[locale.languageCode]!['timeRemaining']!;
  String get systemInfo =>
      _localizedValues[locale.languageCode]!['systemInfo']!;
  String get serviceInfo =>
      _localizedValues[locale.languageCode]!['serviceInfo']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;

  // Additional getters for new strings
  String get chatWithTechnician =>
      _localizedValues[locale.languageCode]!['chatWithTechnician']!;
  String get cancellationTimeExpired =>
      _localizedValues[locale.languageCode]!['cancellationTimeExpired']!;
  String get serviceCancelled =>
      _localizedValues[locale.languageCode]!['serviceCancelled']!;
  String get serviceCancelledSuccessfully =>
      _localizedValues[locale.languageCode]!['serviceCancelledSuccessfully']!;
  String get preparingEquipment =>
      _localizedValues[locale.languageCode]!['preparingEquipment']!;
  String get technicianOnSite =>
      _localizedValues[locale.languageCode]!['technicianOnSite']!;
  String get equipmentStatus =>
      _localizedValues[locale.languageCode]!['equipmentStatus']!;
  String get preparingCharge =>
      _localizedValues[locale.languageCode]!['preparingCharge']!;
  String get notCancellable =>
      _localizedValues[locale.languageCode]!['notCancellable']!;
  String get timeToCancel =>
      _localizedValues[locale.languageCode]!['timeToCancel']!;
  String get lastMinute =>
      _localizedValues[locale.languageCode]!['lastMinute']!;
  String get minutesRemaining =>
      _localizedValues[locale.languageCode]!['minutesRemaining']!;
  String get findingBestTechnician =>
      _localizedValues[locale.languageCode]!['findingBestTechnician']!;
  String get thankYouForUsingVoltGo =>
      _localizedValues[locale.languageCode]!['thankYouForUsingVoltGo']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get technicianWorkingOnVehicle =>
      _localizedValues[locale.languageCode]!['technicianWorkingOnVehicle']!;
  String get since => _localizedValues[locale.languageCode]!['since']!;
  String get initial => _localizedValues[locale.languageCode]!['initial']!;
  String get time => _localizedValues[locale.languageCode]!['time']!;
  String get technicianPreparingEquipment =>
      _localizedValues[locale.languageCode]!['technicianPreparingEquipment']!;
  String get viewTechnicianOnSite =>
      _localizedValues[locale.languageCode]!['viewTechnicianOnSite']!;
  String get chat => _localizedValues[locale.languageCode]!['chat']!;
  String get thankYouForRating =>
      _localizedValues[locale.languageCode]!['thankYouForRating']!;
// Add these getter methods to your AppLocalizations class after the existing ones:

String get welcomeBack => _localizedValues[locale.languageCode]!['welcomeBack']!; 
String get orRegisterWithEmail => _localizedValues[locale.languageCode]!['orRegisterWithEmail']!;

// Processing and loading
  String get processingRequest =>
      _localizedValues[locale.languageCode]!['processingRequest']!;
  String get errorLoadingMap =>
      _localizedValues[locale.languageCode]!['errorLoadingMap']!;
  String get processing =>
      _localizedValues[locale.languageCode]!['processing']!;

// Vehicle verification
  String get vehicleVerification =>
      _localizedValues[locale.languageCode]!['vehicleVerification']!;
  String get checkingVehicle =>
      _localizedValues[locale.languageCode]!['checkingVehicle']!;
  String get verifyingInformation =>
      _localizedValues[locale.languageCode]!['verifyingInformation']!;
  String get verificationNeeded =>
      _localizedValues[locale.languageCode]!['verificationNeeded']!;
  String get couldNotVerifyVehicle =>
      _localizedValues[locale.languageCode]!['couldNotVerifyVehicle']!;
  String get goToRegistration =>
      _localizedValues[locale.languageCode]!['goToRegistration']!;

// Synchronization
  String get syncInProgress =>
      _localizedValues[locale.languageCode]!['syncInProgress']!;
  String get vehicleRegisteredCorrectly =>
      _localizedValues[locale.languageCode]!['vehicleRegisteredCorrectly']!;
  String get syncOptions =>
      _localizedValues[locale.languageCode]!['syncOptions']!;
  String get syncOptionsText =>
      _localizedValues[locale.languageCode]!['syncOptionsText']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get continueAnyway =>
      _localizedValues[locale.languageCode]!['continueAnyway']!;

  String get couldNotGetLocation =>
      _localizedValues[locale.languageCode]!['couldNotGetLocation']!;
  String get errorRequestingService =>
      _localizedValues[locale.languageCode]!['errorRequestingService']!;
  String get noTechniciansAvailable =>
      _localizedValues[locale.languageCode]!['noTechniciansAvailable']!;
  String get needToRegisterVehicle =>
      _localizedValues[locale.languageCode]!['needToRegisterVehicle']!;
  String get authorizationError =>
      _localizedValues[locale.languageCode]!['authorizationError']!;
  String get sessionExpired =>
      _localizedValues[locale.languageCode]!['sessionExpired']!;
  String get serviceUpdatedCorrectly =>
      _localizedValues[locale.languageCode]!['serviceUpdatedCorrectly']!;

// GETTERS NECESARIOS PARA AppLocalizations:
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get logoutConfirmationMessage =>
      _localizedValues[locale.languageCode]!['logoutConfirmationMessage']!;
  String get loggingOut =>
      _localizedValues[locale.languageCode]!['loggingOut']!;
  String get logoutError =>
      _localizedValues[locale.languageCode]!['logoutError']!;
  String get pleaseWait =>
      _localizedValues[locale.languageCode]!['pleaseWait']!;
  String get pleaseWaitMoment =>
      _localizedValues[locale.languageCode]!['pleaseWaitMoment']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get couldNotLoadProfile =>
      _localizedValues[locale.languageCode]!['couldNotLoadProfile']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get editProfile =>
      _localizedValues[locale.languageCode]!['editProfile']!;
  String get securityAndPassword =>
      _localizedValues[locale.languageCode]!['securityAndPassword']!;
  String get chatHistory =>
      _localizedValues[locale.languageCode]!['chatHistory']!;
  String get paymentMethods =>
      _localizedValues[locale.languageCode]!['paymentMethods']!;
  String get vehicle => _localizedValues[locale.languageCode]!['vehicle']!;
  String get manageVehicles =>
      _localizedValues[locale.languageCode]!['manageVehicles']!;
  String get documents => _localizedValues[locale.languageCode]!['documents']!;
// Searching
  String get nearbyTechnicians =>
      _localizedValues[locale.languageCode]!['nearbyTechnicians']!;
  String get thisCanTakeSeconds =>
      _localizedValues[locale.languageCode]!['thisCanTakeSeconds']!;
  String get searchingDots =>
      _localizedValues[locale.languageCode]!['searchingDots']!;

// Status strings
  String get onSite => _localizedValues[locale.languageCode]!['onSite']!;
  String get cancelled => _localizedValues[locale.languageCode]!['cancelled']!;
  String get unknownStatus =>
      _localizedValues[locale.languageCode]!['unknownStatus']!;

// Time-related
  String get fewSecondsAgo =>
      _localizedValues[locale.languageCode]!['fewSecondsAgo']!;
  String get minutesAgo =>
      _localizedValues[locale.languageCode]!['minutesAgo']!;
  String get hoursAgo => _localizedValues[locale.languageCode]!['hoursAgo']!;
  String get daysAgo => _localizedValues[locale.languageCode]!['daysAgo']!;
  String get ago => _localizedValues[locale.languageCode]!['ago']!;

// Vehicle and technician info
  String get serviceVehicle =>
      _localizedValues[locale.languageCode]!['serviceVehicle']!;
  String get notSpecified =>
      _localizedValues[locale.languageCode]!['notSpecified']!;
  String get technician =>
      _localizedValues[locale.languageCode]!['technician']!;

// Cancellation errors and messages
  String get errorCancellingService =>
      _localizedValues[locale.languageCode]!['errorCancellingService']!;
  String get noActiveServiceToCancel =>
      _localizedValues[locale.languageCode]!['noActiveServiceToCancel']!;
  String get timeElapsedMinutes =>
      _localizedValues[locale.languageCode]!['timeElapsedMinutes']!;
  String get limitMinutes =>
      _localizedValues[locale.languageCode]!['limitMinutes']!;
  String get cannotCancelServiceNow =>
      _localizedValues[locale.languageCode]!['cannotCancelServiceNow']!;
  String get technicianAlreadyOnWay =>
      _localizedValues[locale.languageCode]!['technicianAlreadyOnWay']!;
  String get serviceCancelledWithFee =>
      _localizedValues[locale.languageCode]!['serviceCancelledWithFee']!;
  String get serviceCancelledSuccessfullyMessage => _localizedValues[
      locale.languageCode]!['serviceCancelledSuccessfullyMessage']!;

// Basic responses
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get yesCancel => _localizedValues[locale.languageCode]!['yesCancel']!;
  String get areYouSureCancelService =>
      _localizedValues[locale.languageCode]!['areYouSureCancelService']!;
  String get cancelRide =>
      _localizedValues[locale.languageCode]!['cancelRide']!;

// Cancellation time and expiration
  String get blockedFromCancelling =>
      _localizedValues[locale.languageCode]!['blockedFromCancelling']!;
  String get timeForCancellingExpired =>
      _localizedValues[locale.languageCode]!['timeForCancellingExpired']!;
  String get serviceHasExceededTimeLimit =>
      _localizedValues[locale.languageCode]!['serviceHasExceededTimeLimit']!;
  String serviceActiveMinutes(String minutes) =>
      _localizedValues[locale.languageCode]!['serviceActiveMinutes']!
          .replaceAll('{minutes}', minutes);
  String get cancelExpiredService =>
      _localizedValues[locale.languageCode]!['cancelExpiredService']!;
  String get forceExpireService =>
      _localizedValues[locale.languageCode]!['forceExpireService']!;
  String get areYouSureCancelExpiredService =>
      _localizedValues[locale.languageCode]!['areYouSureCancelExpiredService']!;


// Agregar estas líneas en tu clase AppLocalizations

// Complete Profile Screen
String get completeYourProfile =>
    _localizedValues[locale.languageCode]!['completeYourProfile']!;
String get addPhoneToCompleteRegistration =>
    _localizedValues[locale.languageCode]!['addPhoneToCompleteRegistration']!;
String get registeredData =>
    _localizedValues[locale.languageCode]!['registeredData']!;
String get completeProfile =>
    _localizedValues[locale.languageCode]!['completeProfile']!;
String get skipForNow =>
    _localizedValues[locale.languageCode]!['skipForNow']!;
String get profileCompleted =>
    _localizedValues[locale.languageCode]!['profileCompleted']!;
String get phoneNumberWillBeUsedFor =>
    _localizedValues[locale.languageCode]!['phoneNumberWillBeUsedFor']!;
 

// Service information
  String get serviceInformation =>
      _localizedValues[locale.languageCode]!['serviceInformation']!;
  String get timeElapsed =>
      _localizedValues[locale.languageCode]!['timeElapsed']!;
  String get currentStatus =>
      _localizedValues[locale.languageCode]!['currentStatus']!;
  String get noChargesForCancellation =>
      _localizedValues[locale.languageCode]!['noChargesForCancellation']!;
  String get canRequestNewServiceImmediately => _localizedValues[
      locale.languageCode]!['canRequestNewServiceImmediately']!;
  String get yesCancelService =>
      _localizedValues[locale.languageCode]!['yesCancelService']!;

// Service expiration
  String get serviceExpiredAutomatically =>
      _localizedValues[locale.languageCode]!['serviceExpiredAutomatically']!;
  String get serviceActiveForHourWithoutCompletion => _localizedValues[
      locale.languageCode]!['serviceActiveForHourWithoutCompletion']!;
  String get noChargesAppliedForExpiredService => _localizedValues[
      locale.languageCode]!['noChargesAppliedForExpiredService']!;
  String get canRequestNewService =>
      _localizedValues[locale.languageCode]!['canRequestNewService']!;
  String get requestNewService =>
      _localizedValues[locale.languageCode]!['requestNewService']!;
  String get searchForAnotherTechnician =>
      _localizedValues[locale.languageCode]!['searchForAnotherTechnician']!;

// Cancellation reasons
  String get emergenciesOrTechnicalIssues =>
      _localizedValues[locale.languageCode]!['emergenciesOrTechnicalIssues']!;
  String get canRequestNewServiceNow =>
      _localizedValues[locale.languageCode]!['canRequestNewServiceNow']!;
  String get ifTechnicianHasNotArrived =>
      _localizedValues[locale.languageCode]!['ifTechnicianHasNotArrived']!;

// Service details
  String get serviceDetailsInfo =>
      _localizedValues[locale.languageCode]!['serviceDetailsInfo']!;
  String serviceDetailsText(String minutes) =>
      _localizedValues[locale.languageCode]!['serviceDetailsText']!
          .replaceAll('{minutes}', minutes);

// Status change notifications
  String get technicianHasArrived =>
      _localizedValues[locale.languageCode]!['technicianHasArrived']!;
  String get technicianAtLocationPreparingEquipment => _localizedValues[
      locale.languageCode]!['technicianAtLocationPreparingEquipment']!;
  String get serviceStarted =>
      _localizedValues[locale.languageCode]!['serviceStarted']!;
  String get technicianStartedChargingVehicle => _localizedValues[
      locale.languageCode]!['technicianStartedChargingVehicle']!;
  String get serviceCompletedSuccessfully =>
      _localizedValues[locale.languageCode]!['serviceCompletedSuccessfully']!;
  String get vehicleChargedSuccessfully =>
      _localizedValues[locale.languageCode]!['vehicleChargedSuccessfully']!;
  String get statusUpdated =>
      _localizedValues[locale.languageCode]!['statusUpdated']!;
  String get serviceStatusChanged =>
      _localizedValues[locale.languageCode]!['serviceStatusChanged']!;

// Status change titles and messages
  String get technicianConfirmedTitle =>
      _localizedValues[locale.languageCode]!['technicianConfirmedTitle']!;
  String get technicianConfirmedMessage =>
      _localizedValues[locale.languageCode]!['technicianConfirmedMessage']!;
  String get technicianEnRoute =>
      _localizedValues[locale.languageCode]!['technicianEnRoute']!;
  String get technicianHeadingToLocation =>
      _localizedValues[locale.languageCode]!['technicianHeadingToLocation']!;
  String get technicianArrivedTitle =>
      _localizedValues[locale.languageCode]!['technicianArrivedTitle']!;
  String get technicianArrivedMessage =>
      _localizedValues[locale.languageCode]!['technicianArrivedMessage']!;
  String get serviceInitiatedTitle =>
      _localizedValues[locale.languageCode]!['serviceInitiatedTitle']!;
  String get serviceInitiatedMessage =>
      _localizedValues[locale.languageCode]!['serviceInitiatedMessage']!;
  String get serviceCompletedTitle =>
      _localizedValues[locale.languageCode]!['serviceCompletedTitle']!;
  String get serviceCompletedMessage =>
      _localizedValues[locale.languageCode]!['serviceCompletedMessage']!;

// Service progress
  String get technicianWillDocumentProgress =>
      _localizedValues[locale.languageCode]!['technicianWillDocumentProgress']!;
  String get serviceProgress =>
      _localizedValues[locale.languageCode]!['serviceProgress']!;
  String get from => _localizedValues[locale.languageCode]!['from']!;
  String get batteryLevel =>
      _localizedValues[locale.languageCode]!['batteryLevel']!;
  String get chargingTime =>
      _localizedValues[locale.languageCode]!['chargingTime']!;
  String get min => _localizedValues[locale.languageCode]!['min']!;

// UI elements
  String get followInRealTime =>
      _localizedValues[locale.languageCode]!['followInRealTime']!;
  String get averageRating =>
      _localizedValues[locale.languageCode]!['averageRating']!;
  String get phoneCall => _localizedValues[locale.languageCode]!['phoneCall']!;
  String get sendMessage =>
      _localizedValues[locale.languageCode]!['sendMessage']!;
  String get message => _localizedValues[locale.languageCode]!['message']!;
  String get equipmentReady =>
      _localizedValues[locale.languageCode]!['equipmentReady']!;
  String get startingCharge =>
      _localizedValues[locale.languageCode]!['startingCharge']!;
  String get connectingTechnician =>
      _localizedValues[locale.languageCode]!['connectingTechnician']!;

  String get serviceHistory =>
      _localizedValues[locale.languageCode]!['serviceHistory']!;
  String get reviewPreviousServices =>
      _localizedValues[locale.languageCode]!['reviewPreviousServices']!;
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get accepted => _localizedValues[locale.languageCode]!['accepted']!;
  String get enRoute => _localizedValues[locale.languageCode]!['enRoute']!;
  String get charging => _localizedValues[locale.languageCode]!['charging']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get yesterday => _localizedValues[locale.languageCode]!['yesterday']!;
  String get errorLoadingHistory =>
      _localizedValues[locale.languageCode]!['errorLoadingHistory']!;
  String get noServicesInHistory =>
      _localizedValues[locale.languageCode]!['noServicesInHistory']!;
  String get requestService =>
      _localizedValues[locale.languageCode]!['requestService']!;

// Títulos y navegación
  String get registerElectricVehicle =>
      _localizedValues[locale.languageCode]!['registerElectricVehicle']!;
  String get step => _localizedValues[locale.languageCode]!['step']!;
  String get off => _localizedValues[locale.languageCode]!['of']!;

// Secciones del formulario
  String get vehicleInformation =>
      _localizedValues[locale.languageCode]!['vehicleInformation']!;
  String get identification =>
      _localizedValues[locale.languageCode]!['identification']!;
  String get technicalSpecs =>
      _localizedValues[locale.languageCode]!['technicalSpecs']!;

// Labels de campos
  String get brand => _localizedValues[locale.languageCode]!['brand']!;
  String get model => _localizedValues[locale.languageCode]!['model']!;
  String get year => _localizedValues[locale.languageCode]!['year']!;
  String get plate => _localizedValues[locale.languageCode]!['plate']!;
  String get color => _localizedValues[locale.languageCode]!['color']!;
  String get connectorType =>
      _localizedValues[locale.languageCode]!['connectorType']!;

// Opciones generales
  String get other => _localizedValues[locale.languageCode]!['other']!;

// Colores
  String get white => _localizedValues[locale.languageCode]!['white']!;
  String get black => _localizedValues[locale.languageCode]!['black']!;
  String get gray => _localizedValues[locale.languageCode]!['gray']!;
  String get silver => _localizedValues[locale.languageCode]!['silver']!;
  String get red => _localizedValues[locale.languageCode]!['red']!;
  String get blue => _localizedValues[locale.languageCode]!['blue']!;
  String get green => _localizedValues[locale.languageCode]!['green']!;

// Hints y placeholders
  String get writeBrandHint =>
      _localizedValues[locale.languageCode]!['writeBrandHint']!;
  String get selectOrEnterBrand =>
      _localizedValues[locale.languageCode]!['selectOrEnterBrand']!;
  String get modelHint => _localizedValues[locale.languageCode]!['modelHint']!;
  String get plateHint => _localizedValues[locale.languageCode]!['plateHint']!;
  String get specifyColor =>
      _localizedValues[locale.languageCode]!['specifyColor']!;
  String get colorHint => _localizedValues[locale.languageCode]!['colorHint']!;
  String get enterColor =>
      _localizedValues[locale.languageCode]!['enterColor']!;

// Mensajes de éxito y error
  String get vehicleRegistrationError =>
      _localizedValues[locale.languageCode]!['vehicleRegistrationError']!;
  String get vehicleRegistered =>
      _localizedValues[locale.languageCode]!['vehicleRegistered']!;
  String get vehicleRegisteredSuccess =>
      _localizedValues[locale.languageCode]!['vehicleRegisteredSuccess']!;
  String get continueText =>
      _localizedValues[locale.languageCode]!['continueText']!;

// Mensajes de validación específicos
  String get selectBrandMessage =>
      _localizedValues[locale.languageCode]!['selectBrandMessage']!;
  String get enterModelMessage =>
      _localizedValues[locale.languageCode]!['enterModelMessage']!;
  String get enterYearMessage =>
      _localizedValues[locale.languageCode]!['enterYearMessage']!;
  String get validYearMessage =>
      _localizedValues[locale.languageCode]!['validYearMessage']!;
  String get enterPlateMessage =>
      _localizedValues[locale.languageCode]!['enterPlateMessage']!;
  String get selectColorMessage =>
      _localizedValues[locale.languageCode]!['selectColorMessage']!;
  String get specifyColorMessage =>
      _localizedValues[locale.languageCode]!['specifyColorMessage']!;
  String get selectConnectorMessage =>
      _localizedValues[locale.languageCode]!['selectConnectorMessage']!;
  String get completeRequiredFields =>
      _localizedValues[locale.languageCode]!['completeRequiredFields']!;

// Mensajes de validación generales
  String get fieldRequired =>
      _localizedValues[locale.languageCode]!['fieldRequired']!;
  String get numbersOnly =>
      _localizedValues[locale.languageCode]!['numbersOnly']!;
  String get yearRange => _localizedValues[locale.languageCode]!['yearRange']!;
  String get and => _localizedValues[locale.languageCode]!['and']!;
  String get plateMinLength =>
      _localizedValues[locale.languageCode]!['plateMinLength']!;

// Botones de navegación
  String get previous => _localizedValues[locale.languageCode]!['previous']!;
  String get next => _localizedValues[locale.languageCode]!['next']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;

// Success messages
  String get thankYouForYourRating =>
      _localizedValues[locale.languageCode]!['thankYouForYourRating']!;

  String get errorRefreshingServiceData =>
      _localizedValues[locale.languageCode]!['errorRefreshingServiceData']!;
  String get noActiveService =>
      _localizedValues[locale.languageCode]!['noActiveService']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
