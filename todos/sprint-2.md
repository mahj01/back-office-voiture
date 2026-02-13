sprint-2
    Momban'ny  vehicule :
        -id 
        -reference
        -nombre place
        -type carburant ('D','Es','H','El') 
    Asa 1 : Manao CRUD Vehicule (Liste , modifier , supprimer , Ajouter)
    Asa 2 : Proteger appel API
        -Mi creer table token (id, valeur (afak generena mampiasa GUID , UID 16 caractere oatra) , date d'expiration(misy heure))
            -Tsisy interface fa manana MAIN???
            -Preparation fotsiny fa mbola tsy hanaovana protection
    Tohiny : Mandefa token amzay rehefa miantso API
        -Rehefa ao amleh liste amzay :
            Misy ve le token ? 
                -Oui : jerena ny date d'expiration any
                -Non : Tsy autorized
        