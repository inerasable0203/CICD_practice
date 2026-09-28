# CI/CD 실습 카운터

버튼을 누르면 숫자가 바뀌는 정적 웹페이지입니다. 외부 패키지나 빌드 단계 없이 GitHub Actions의 검사와 GitHub Pages 배포를 연습할 수 있습니다.

## 로컬 실행

```bash
python3 -m http.server 8000
```

브라우저에서 <http://localhost:8000>을 엽니다. 검사는 Python과 Node.js 24로 실행합니다.

```bash
python3 -m unittest discover -s tests
node --test tests/counter.test.mjs
```

## CI/CD 흐름

1. Pull Request를 열면 페이지 검사가 실행됩니다.
2. `main`에 push하면 같은 검사를 통과한 후 배포 파일을 artifact로 준비합니다.
3. `github-pages` 환경에 수동 승인이 설정되어 있으면 승인 후 GitHub Pages에 배포됩니다.
4. GitHub 저장소의 **Settings → Pages → Build and deployment → Source**를 **GitHub Actions**로 설정합니다.
5. **Actions** 탭에서 `CI and Pages` 실행 결과를 확인합니다.

배포된 GitHub Pages 웹페이지는 공개됩니다.

연습하려면 제목을 바꾸고 테스트의 예상 제목도 함께 수정한 뒤 Pull Request를 열어 보세요. 테스트가 실패하는 경우와 통과하는 경우를 모두 확인할 수 있습니다.
