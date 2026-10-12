# Publicar o AutoBoost no GitHub

## 1. Usar o pacote preparado

Extraia este ZIP em uma nova pasta, por exemplo `C:\dev\autoboost_github`. Abra no VS Code a pasta que contém `pubspec.yaml`. Não extraia sobre o projeto original: mantenha a versão que já funciona como cópia de segurança.

Execute `flutter pub get` e `flutter analyze`. O pacote mantém as dependências e inclui comentários no código. Caches, caminhos locais do SDK e arquivos `.bak` foram retirados da cópia de entrega.

## 2. Criar o repositório

Entre em https://github.com/new na sua conta. Nome sugerido: `autoboost`. Escolha público se puder compartilhar o projeto ou privado se precisar restringir acesso. Como este pacote já possui README e .gitignore, não inicialize esses arquivos no site. Não selecione licença sem decidir qual deseja usar.

## 3. Preparar o primeiro commit

No terminal, dentro da pasta extraída, execute uma linha por vez:

```powershell
git init -b main
git config user.name "Adrian Carvalho Garcia"
git config user.email "SEU_EMAIL_DE_COMMIT"
git add .
git status
git commit -m "Entrega inicial: AutoBoost com SQLite e documentação"
```

Substitua o e-mail pelo endereço que deseja associar aos commits; pode usar o endereço noreply exibido nas configurações de e-mail do GitHub. Os comandos `git config` acima afetam somente este repositório. Confira `git status` antes do commit. Se a pasta já tiver Git, inspecione o repositório existente antes de seguir este roteiro.

## 4. Enviar

Copie a URL HTTPS do repositório criado e substitua `SEU_USUARIO` abaixo:

```powershell
git remote add origin https://github.com/SEU_USUARIO/autoboost.git
git remote -v
git push -u origin main
```

Se o Git abrir autenticação no navegador, conclua na sua conta. Não coloque senha ou token no código, na URL do remote ou em mensagens. Se `origin` já existir, confira `git remote -v` antes de alterar qualquer configuração. Não use push forçado para resolver conflitos sem entender a causa.

## 5. Conferir e entregar

Abra o repositório no navegador e confira README, pasta lib, documentação, pubspec.yaml e pubspec.lock. Não basta enviar o ZIP para que o GitHub mostre o código: envie os arquivos extraídos por Git.

O APK não está neste ZIP. Se quiser distribuí-lo pelo GitHub, crie uma Release com tag `v1.0.0` e anexe o `app-release.apk` que você gerou. Informe que é demonstração acadêmica e que o APK usa assinatura de debug. Não inclua o banco com dados pessoais.

Referência: https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github
