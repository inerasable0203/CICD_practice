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

1. Pull Request에서 홈페이지 파일이 바뀌면 페이지 검사가 실행됩니다. 다른 파일만 바뀌면 필수 검사 `test`는 통과하되 페이지 테스트는 실행하지 않습니다.
2. 홈페이지 파일을 `main`에 push하면 검사를 통과한 후 배포 파일을 artifact로 준비합니다. Airflow 파일만 바뀐 경우에는 홈페이지 테스트와 배포를 건너뜁니다.
3. `github-pages` 환경에 수동 승인이 설정되어 있으면 승인 후 GitHub Pages에 배포됩니다.
4. GitHub 저장소의 **Settings → Pages → Build and deployment → Source**를 **GitHub Actions**로 설정합니다.
5. **Actions** 탭에서 `CI and Pages` 실행 결과를 확인합니다.

배포된 GitHub Pages 웹페이지는 공개됩니다.

연습하려면 제목을 바꾸고 테스트의 예상 제목도 함께 수정한 뒤 Pull Request를 열어 보세요. 테스트가 실패하는 경우와 통과하는 경우를 모두 확인할 수 있습니다.

## Docker 이미지 실습

Airflow 이미지에 매출 CSV를 읽어 카테고리별 합계를 만드는 `sales_summary` DAG를 넣었습니다. 로컬에서 이미지를 만들고 Airflow를 실행합니다.

```bash
docker build -t airflow-practice:local .
docker run -d --name airflow-practice -p 127.0.0.1:18081:8080 airflow-practice:local standalone
```

<http://localhost:18081>에서 `sales_summary` DAG를 실행합니다. 로그인 비밀번호는 `docker exec airflow-practice cat /opt/airflow/simple_auth_manager_passwords.json.generated`로 확인할 수 있습니다. DAG가 끝나면 `docker cp airflow-practice:/tmp/sales_summary.csv ./sales_summary.csv`로 결과를 가져오고, `docker stop airflow-practice`로 종료합니다. 현재 결과는 `books=2500`, `stationery=300`입니다.

`Docker image` 워크플로는 Pull Request에서 이미지를 빌드하고 DAG를 실행하며, `main`에서는 같은 이미지를 `ghcr.io/inerasable0203/cicd_practice`에 커밋 SHA와 `latest` 태그로 발행합니다. GHCR 패키지는 처음 생성되면 비공개일 수 있으므로, 인증 없이 내려받으려면 패키지 설정에서 공개로 변경해야 합니다.

GHCR 발행 후에는 `docker pull ghcr.io/inerasable0203/cicd_practice:latest`로 내려받아 로컬 이미지 대신 실행할 수 있습니다.

## 로컬 Airflow 자동 업데이트

`main`에 새 Docker 이미지가 발행되면 로컬 타이머가 2분마다 GHCR을 확인하고 `airflow-practice`를 같은 `localhost:18081` 주소로 다시 만듭니다. PC가 켜져 있고 사용자 systemd가 실행 중일 때 동작합니다. 처음 전환할 때 기존 컨테이너의 `/opt/airflow`를 `cicd-practice-airflow-data` 볼륨으로 복사해 실행 기록과 로그인 비밀번호를 보존합니다. 기존 컨테이너는 `airflow-practice-before-compose`라는 이름으로 중지된 채 남깁니다.

이 저장소가 `~/CICD_practice`에 있을 때 다음 명령으로 타이머를 등록합니다.

```bash
systemctl --user link "$PWD/systemd/airflow-update.service" "$PWD/systemd/airflow-update.timer"
systemctl --user enable --now airflow-update.timer
systemctl --user start airflow-update.service
```

마지막 명령은 업데이트를 바로 한 번 확인합니다. 새 이미지가 아직 발행되지 않았다면 기존 컨테이너를 유지하고 다음 확인을 기다립니다. 상태는 `systemctl --user status airflow-update.timer`와 `journalctl --user -u airflow-update.service -n 50`으로 볼 수 있습니다.
