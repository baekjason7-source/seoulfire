-- ============================================================
--  서울소방 탁구동호회 대회 플랫폼 - 데이터베이스 설정
--  Supabase > SQL Editor 에 붙여넣고 Run 하세요.
-- ============================================================

-- 1) 참가 신청 테이블
create table if not exists entries (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz default now(),
  event       text not null,              -- single | double | team
  name        text not null,
  org         text,
  div         text not null,              -- 1부~6부 / 복식은 "합N부" / 단체는 팀 부수
  p1          text,
  p2          text,
  phone       text,
  paid        boolean default false,
  meta        jsonb default '{}'::jsonb   -- 복식 선수별 정보·합부수, 단체 명단 등
);

-- ★ 이미 테이블을 만든 경우: 아래 한 줄만 실행하면 meta 칸이 추가됩니다.
alter table entries add column if not exists meta jsonb default '{}'::jsonb;

-- 2) 대회 진행 상태(조편성·예선·본선 결과)
create table if not exists tstate (
  event       text primary key,
  data        jsonb not null default '{}',
  updated_at  timestamptz default now()
);

-- 3) 접근 권한
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on entries to anon, authenticated;
grant select, insert, update, delete on tstate  to anon, authenticated;

-- 4) RLS + 정책 (v1: 누구나 신청·조회. 관리자 구분은 앱 비밀번호)
alter table entries enable row level security;
alter table tstate  enable row level security;
drop policy if exists entries_all on entries;
drop policy if exists tstate_all  on tstate;
create policy entries_all on entries for all using (true) with check (true);
create policy tstate_all  on tstate  for all using (true) with check (true);

-- ============================================================
-- 5) 실시간 반영(선택) — 운영진이 입력하면 다른 기기에 자동 표시
--    아래를 SQL Editor에서 한 번 실행하세요. (이미 적용돼 있으면 그냥 통과)
-- ============================================================
do $$
begin
  begin alter publication supabase_realtime add table entries; exception when others then null; end;
  begin alter publication supabase_realtime add table tstate;  exception when others then null; end;
end $$;
