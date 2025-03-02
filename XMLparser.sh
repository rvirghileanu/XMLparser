#!/bin/bash


#FUNCȚII PENTRU MENIUL DE PRELUCRARE A STRUCTURILOR DE DATE



# Funcța de citire a tuturor valorilor unui tag
read_tag(){
    local file=$1
    local tag=$2
    echo "Toate valorile pentru <$tag>:"
    grep -oP "(?<=<$tag>).*?(?=</$tag>)" "$file"
}

# Funcția pentru citirea întregului conținut al unui element
read_element() {
    local file=$1
    local main_tag=$2
    local attribute=$3
    local value=$4

    # Extragem conținutul dorit din XML
    awk -v tag="$main_tag" -v attr="$attribute" -v val="$value" '
    BEGIN { found = 0 }
    # Eliminăm spațiile din față și din spate
    {
        gsub(/^[ \t]+|[ \t]+$/, "")
    }
    $0 ~ "<" tag ">" {
        found = 0
        buffer = ""
    }
    found == 0 && $0 ~ "<" attr ">" val "</" attr ">" {
        found = 1
    }
    found == 1 {
        buffer = buffer "\n" $0
        if ($0 ~ "</" tag ">") {
            print gensub(/^[ \t]+|[ \t]+$/, "", "g", buffer)
            exit
        }
    }' "$file" | awk -F'[<>]' '!/<[^\/]/ {next} {print $3}'
}

# Funcția de creare a unui fișier XML nou
add_file() {
    local file=$1
    if [[ -z "$file" ]]; then
        echo "Eroare: Nu ați introdus niciun nume de fișier."
        return 1
   fi

    # Scrierea conținutului XML în fișier
    cat <<EOF > "$file"
<?xml version="1.0" encoding="UTF-8"?>
EOF

    echo "A fost creat un fișier XML nou: $file"
}


# Funcția pentru a adăuga un element într-un fișier XML
add_element() {
    local file="$1"
    local element_tag="$2"
    local attribute_tag="$3"
    local content="$4"

    if [[ ! -f "$file" ]]; then
        echo "Eroare: Fișierul $file nu există!"
        return 1
    fi

    # Detectarea tagului rădăcină
    local root_tag=$(grep -oP '(?<=<)[^/?> ]+' "$file" | head -1)
    if [[ -z "$root_tag" ]]; then
        echo "Eroare: Nu s-a găsit un tag rădăcină valid în $file!"
        return 1
    fi

    # Crearea structurii noului element
    local new_element="  <$element_tag>
    <$attribute_tag>$content</$attribute_tag>
  </$element_tag>"

    # Inserarea înainte de tagul de închidere al rădăcinii
    local tmp_file=$(mktemp)
    awk -v root="</$root_tag>" -v element="$new_element" '
        $0 ~ root { print element }
        { print $0 }
    ' "$file" > "$tmp_file"

    # Suprascrierea fișierului inițial
    if mv "$tmp_file" "$file"; then
        echo "Succes: Elementul a fost adăugat în $file."
    else
        echo "Eroare: Nu s-a putut actualiza $file!"
        rm -f "$tmp_file"  # \șterge fișierul temporar în caz de eroare
        return 1
    fi
}
 


#FUNCȚII PENTRU PRELUCRAREA DATELOR DINTR-O APLICAȚIE


# Funcție pentru a extrage valoarea unui anumit tag
extract_tag() {
  local xml="$1"
  local tag="$2"
  echo "$xml" | grep -oP "<$tag>(.*?)</$tag>" | sed -e "s|<$tag>||" -e "s|</$tag>||"
  echo ""
}

# Funcție pentru a extrage valoarea unui atribut
extract_attribute() {
  local xml="$1"
  local tag="$2"
  local attr="$3"
  echo "$xml" | grep -oP "<$tag [^>]*$attr=\"[^\"]*\"" | sed -e "s|.*$attr=\"||" -e "s|\".*||"
}

# FUNCȚIILE PENTRU MENIUL SECUNDAR DE PROCESARE A STRUCTURILOR DE DATE

meniu1(){
    while true; do
        echo ""
        echo "=== Parsarea fișierelor XML - Structuri de date ==="
        echo "1. Citește un tag"
        echo "2. Citește un element"
        echo "3. Creează un fișier XML nou"
        echo "4. Adaugă un element într-un fișier XML existent"
        echo "5. Ieșire"
        echo -n "Alegeți o opțiune (1-5): "
        echo ""
        read optiune

    case $optiune in
        1)
	          echo ""
            # Citim datele de intrare
            echo -n "Introduceți numele fișierului XML: "
            read file
            echo -n "Introduceți numele tagului de citit: "
            read tag
            # Apelăm funcția pentru citirea tuturor valorilor unui tag
            read_tag "$file" "$tag"

	          # Întrebăm utilizatorul dacă dorește să continue

	          read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

            ;;

        2)
	          echo ""
            # Citim datele de intrare
            echo -n "Introduceți numele fișierului XML: "
            read file
            echo -n "Introduceți tag-ul elementului: "
            read element_tag
            echo -n "Introduceți tag-ul primului atribut al elementului: "
            read element_atr
            echo -n "Introduceți valoarea atributului elementului căutat: "
            read atr_value
            # Apelăm funcția pentru citirea întregului conținut al unui element
            read_element "$file" "$element_tag" "$element_atr" "$atr_value"

	          # Întrebăm utilizatorul dacă dorește să continue

	          read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

            ;;

        3)
	          echo ""
            # Citim datele de intrare
            echo -n "Introduceți numele fișierului XML pe care doriți să îl creați: "
            read file
            # Apelăm funcția pentru crearea unui fișier XML nou
            add_file "$file"
            # Adăugăm tag-urile ”root” în fișierul nou creat
            echo "<root>" >> "$file"
            echo "</root>" >> "$file"
            echo -n "Fișierul XML cu numele <$file> a fost creat cu succes!"

	          # Întrebăm utilizatorul dacă dorește să continue

	          read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

            ;;

        4)
            echo ""
            # Citim datele de intrare
            echo -n "Introdueți numele fișierului XML: "
            read file
            echo -n "Introduceți tagul elementului: "
            read element_tag
            echo -n "Introduceți tagul primului atribut al elementului: "
            read element_atr
            echo -n "Introduceți conținutul dintre taguri: "
            read content
            # Apelăm funcția pentru adăugarea unui nou element
            add_element "$file" "$element_tag" "$element_atr" "$content"

            # Întrebăm utilizatorul dacă dorește să continue

	          read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

	          ;;


	5)
            echo "La revedere!"
            exit 0
            ;;

	*)
            echo ""
            echo "Opțiune invalidă!"

            # Întrebăm utilizatorul dacă dorește să continue

	          read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 
            ;;
    esac

done
}


# FUNCȚIA PENTRU MENIUL SECUNDAR DE PROCESARE A DATELOR DINTR-O APLICAȚIE

meniu2(){

# Cerem un fișier de intrare
if [[ $# -eq 0 ]]; then
  echo "Introduceți numele fișierului dorit: "
fi

read XML_FILE


# Verificăm dacă fișierul există
if [[ ! -f $XML_FILE ]]; then
  echo "Eroare: Fișierul XML '$XML_FILE' nu a fost găsit!"
  exit 1
fi

XML_CONTENT=$(cat "$XML_FILE")

# Extragem metadatele
APP_ID=$(extract_attribute "$XML_CONTENT" "application" "id")
APP_NAME=$(extract_attribute "$XML_CONTENT" "application" "name")
APP_INFO=$(extract_attribute "$XML_CONTENT" "application" "info")
DESCRIPTION=$(extract_tag "$XML_CONTENT" "description")
AUTHOR=$(extract_tag "$XML_CONTENT" "author")
EMAIL=$(extract_tag "$XML_CONTENT" "email")




while true; do
  echo "Parsarea fișierelor XML - date dintr-o aplicație"
  echo "1. Afișează Metadatele Aplicației"
  echo "2. Afișează Detalii Despre Configurare"
  echo "3. Afișează Parametri"
  echo "4. Ieșire"
  read -p "Alegeți o opțiune (1-4): " optiune

  case $optiune in
    1)
      # Afișăm Metadatele Aplicației
      echo "ID Aplicație: $APP_ID"
      echo "Nume Aplicație: $APP_NAME"
      echo "Info: $APP_INFO"
      echo "Descriere: $DESCRIPTION"
      echo "Autor: $AUTHOR"
      echo "Email: $EMAIL"

      # Întrebăm utilizatorul dacă dorește să continue

	    read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 
      ;;
      
    2)
      # Extragem detalii despre configurare
      HELP_URL=$(extract_tag "$XML_CONTENT" "help_url")
      PARAM_TEMPLATE=$(extract_tag "$XML_CONTENT" "param_template")
      PARAM_TABLE_TEMPLATE=$(extract_tag "$XML_CONTENT" "param_table_template")

      # Afișăm detaliile despre configurare
      echo "URL Ajutor: $HELP_URL"
      echo "Șablon Parametri: $PARAM_TEMPLATE"
      echo "Șablon Tabel Parametri: $PARAM_TABLE_TEMPLATE"

      # Întrebăm utilizatorul dacă dorește să continue

	    read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

      ;;
      
    3)
      # Extragem parametrii
      echo "Parametri:"
      PARAMETERS=$(echo "$XML_CONTENT" | grep -oP "<text [^>]*>|<select [^>]*>")

      # Procesăm fiecare parametru
      while IFS= read -r PARAM; do
        PARAM_ID=$(echo "$PARAM" | grep -oP "id=\"[^\"]*\"" | sed -e "s|id=\"||" -e "s|\"||")
        PARAM_NAME=$(echo "$PARAM" | grep -oP "name=\"[^\"]*\"" | sed -e "s|name=\"||" -e "s|\"||")
        PARAM_INFO=$(echo "$PARAM" | grep -oP "info=\"[^\"]*\"" | sed -e "s|info=\"||" -e "s|\"||")
        OPTIONAL=$(echo "$PARAM" | grep -oP "optional=\"[^\"]*\"" | sed -e "s|optional=\"||" -e "s|\"||")
        
        # Afișăm fiecare parametru
        echo "  ID: $PARAM_ID"
        echo "  Nume: $PARAM_NAME"
        echo "  Info: $PARAM_INFO"
        echo "  Optional: ${OPTIONAL:-da}"
      done <<< "$PARAMETERS"

      # Întrebăm utilizatorul dacă dorește să continue

	    read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 

      ;;
      
    4)
      echo "La revedere!"
      exit 0
      ;;
      
    *)
      echo "Opțiune invalidă. Alegeți între 1-4."

      # Întrebăm utilizatorul dacă dorește să continue

	    read -p "Apăsați tasta [ENTER] pentru a reveni la meniu." 
      ;;
  esac

done

}



# MENIUL PRINCIPAL

    echo ""
    echo "-------PROIECT Instrumente și Tehnici de Bază în Informatică-------"
    echo "------------Titlu proiect: Parsarea fișierelor XML------------"
    echo "-------------------- 2024-2025 --------------------"
    echo ""
    echo "Echipa: Spice Girls                |                Studenți:"
    echo "                                               Marțole Ilinca-Maria"
    echo "                                                Pleșca Maria-Erika"
    echo "                                            Vîrghileanu Maria-Roberta"
    echo ""
    echo "Ce tip de date doriți să parsați?"
    echo "1. Structuri de date dintr-un fișier XML"
    echo "2. Date dintr-o aplicație"
    echo "Alegeți opțiunea (1-2): "

    read optiune_meniu

    case $optiune_meniu in
    1) 
    meniu1
    ;;
    2) 
    meniu2
    ;;
    *) 
    echo "Opțiune invalidă!"
    ;;
    esac

