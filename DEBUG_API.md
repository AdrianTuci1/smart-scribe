# Depanare API VoiceScribe

## Problemă: "Required key: :secret_access_key is nil in config!"

Dacă întâmpinați această eroare, urmați pașii de mai jos pentru a rezolva problema:

### 1. Verificați variabilele de mediu

Rulați următoarea comandă pentru a verifica dacă variabilele de mediu sunt setate corect:

```bash
docker-compose exec backend printenv | grep AWS
```

Ar trebui să vedeți:
```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-central-1
```

### 2. Verificați fișierul .env

Asigurați-vă că aveți un fișier `.env` în rădăcina proiectului cu următoarele variabile:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-central-1
```

### 3. Reporniți serviciul

După modificarea fișierelor de configurare, reporniți serviciul backend:

```bash
docker-compose down
docker-compose up --build
```

### 4. Testare cu httpie

Pentru a testa dacă totul funcționează corect, folosiți:

```bash
# Obțineți un token JWT valid prin autentificare în aplicația frontend
# Apoi rulați:

http GET http://localhost:4000/api/v1/transcripts "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5. Verificări suplimentare

Dacă problema persistă, verificați următoarele:

1. Verificați dacă configurația ExAws este corectă în `config/config.exs`
2. Verificați dacă variabilele de mediu sunt accesibile în container:
   ```bash
   docker-compose exec backend iex -S mix
   # În iex, rulați:
   System.get_env("AWS_SECRET_ACCESS_KEY")
   ```

### 6. Debug în interiorul containerului

Pentru a investiga mai departe, conectați-vă la container:

```bash
docker-compose exec backend bash
```

Apoi verificați manual configurația și variabilele de mediu.

## Alte erori comune

### Eroare de conexiune la DynamoDB

Dacă primiți erori de conexiune la DynamoDB:
1. Verificați dacă regiunea este corectă (`eu-central-1`)
2. Verificați dacă cheile AWS au permisiunile necesare pentru DynamoDB

### Eroare de autentificare

Dacă primiți erori de autentificare:
1. Verificați dacă token-ul JWT este valid
2. Verificați configurația Cognito în `cognito_auth.ex`
3. Verificați dacă issuer-ul JWT este corect

## Instrucțiuni pentru testare

1. Configurați variabilele de mediu
2. Porniți serviciul backend cu `docker-compose up --build`
3. Folosiți cererile din `api_test_requests.http` pentru a testa API-ul
4. Pentru fiecare cerere, înlocuiți `YOUR_JWT_TOKEN` cu un token valid