# play-terraform-aws
Pruebas para despliegue de infraestructura como código

Necesario tener instalado en el cliente:

- Terraform client
- AWS client
- Opcionalmente Visual Studio Code

Los ficheros necesarios:

    main.tf
    outputs.tf
    
    git clone https://github.com/jmvigueras/play-terraform-aws

(Lo único a tener en cuenta, deben estar desplegados previamente una imagen AMI que se usará como plantilla y unas credenciales ssh para configurar en las instancias EC2)

    ami -> ami-0b2a43be9744bcf11
    key-name -> ingress-test-terraform-eu-west-2

En el PC desde donde se lanzan los despliegues:

Configuración de acceso a los recursos de AWS: 

    # aws configure
    AWS Access Key ID []: xxxxxx
    AWS Secret Access Key []: xxxxxx
    Default region name []:
    Default output format [None]:

Una vez configurados, copiar los ficheros main.tf y outputs.tf en el directorio y ejecutar los siguientes comandos:

    # terraform init -> (inicio del plan de despliegue y creación de lo necesario para hacerlo)
    # terraform apply -> (despliegue de la infraestuctura)
    # terraform destroy -> (borrar toda la infraestructura
    
Y con esto ya tenemos desplegado todo :)
