-- =====================================================
-- 당직표 자동화 시스템 - Supabase 초기 설정
-- Supabase 대시보드 > SQL Editor 에서 전체 실행
-- =====================================================

-- 1. 영업조 테이블
create table if not exists teams (
  id serial primary key,
  name text not null,
  color text not null default '#cccccc',
  active boolean default true,
  members jsonb default '[]'::jsonb,
  sort_order int default 0
);

-- 2. 영업일 테이블
create table if not exists business_periods (
  id serial primary key,
  period_key text unique not null,
  label text,
  start_date date not null,
  end_date date not null,
  work_days int default 0
);

-- 3. 공휴일 테이블
create table if not exists holidays (
  id serial primary key,
  date date unique not null,
  name text not null
);

-- 4. 일별 배정 테이블 (날짜당 1조)
create table if not exists schedules (
  id serial primary key,
  date date unique not null,
  team_id int references teams(id) on delete set null,
  schedule_type text default 'normal',
  updated_at timestamptz default now()
);

-- 5. 주말 근무 보상 테이블 (근무일 + 직원별 1건)
create table if not exists compensations (
  id serial primary key,
  work_date date not null,
  member_name text not null,
  period_key text not null,
  work_type text not null default 'single', -- 'single' | 'both'
  comp_type text,                           -- 'half_am' | 'half_pm' | 'weekend_dayoff' | 'carried'
  comp_date date,
  confirmed boolean default false,
  carried_to text,
  created_at timestamptz default now(),
  unique(work_date, member_name)
);

-- 6. 월차 테이블 (기간 + 직원별 1건)
create table if not exists monthly_dayoffs (
  id serial primary key,
  period_key text not null,
  member_name text not null,
  dayoff_date date,
  confirmed boolean default false,
  unique(period_key, member_name)
);

-- 7. 알림 테이블
create table if not exists notifications (
  id serial primary key,
  notif_type text not null,
  message text not null,
  target_date date,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- =====================================================
-- RLS 비활성화 (내부 업무 도구)
-- =====================================================
alter table teams disable row level security;
alter table business_periods disable row level security;
alter table holidays disable row level security;
alter table schedules disable row level security;
alter table compensations disable row level security;
alter table monthly_dayoffs disable row level security;
alter table notifications disable row level security;

-- =====================================================
-- 실시간 구독 활성화
-- =====================================================
alter publication supabase_realtime add table schedules;
alter publication supabase_realtime add table compensations;
alter publication supabase_realtime add table monthly_dayoffs;
alter publication supabase_realtime add table notifications;

-- =====================================================
-- 기본 영업조 데이터 (4조)
-- =====================================================
insert into teams (name, color, active, members, sort_order) values
('1조', '#82C87A', true, '["서창규","박초현"]'::jsonb, 1),
('2조', '#F5D243', true, '["유동우","고재윤"]'::jsonb, 2),
('3조', '#F4A24A', true, '["박원빈"]'::jsonb, 3),
('4조', '#5BA3F5', true, '["김태욱","윤다슬"]'::jsonb, 4),
('5조', '#C084FC', false, '[]'::jsonb, 5),
('6조', '#F87171', false, '[]'::jsonb, 6)
on conflict do nothing;

-- =====================================================
-- 2026년 영업일 기준 데이터
-- =====================================================
insert into business_periods (period_key, label, start_date, end_date, work_days) values
('2026-01', '1월 영업', '2026-01-13', '2026-02-10', 29),
('2026-02', '2월 영업', '2026-02-11', '2026-03-16', 34),
('2026-03', '3월 영업', '2026-03-17', '2026-04-13', 28),
('2026-04', '4월 영업', '2026-04-14', '2026-05-13', 30),
('2026-05', '5월 영업', '2026-05-14', '2026-06-11', 29),
('2026-06', '6월 영업', '2026-06-12', '2026-07-14', 33)
on conflict do nothing;

-- =====================================================
-- 2026년 공휴일 데이터
-- =====================================================
insert into holidays (date, name) values
('2026-01-01', '신정'),
('2026-02-16', '설날 연휴'),
('2026-02-17', '설날'),
('2026-02-18', '설날 연휴'),
('2026-03-01', '삼일절'),
('2026-03-02', '대체공휴일'),
('2026-05-01', '근로자의 날'),
('2026-05-05', '어린이날'),
('2026-05-25', '대체공휴일'),
('2026-06-06', '현충일'),
('2026-08-15', '광복절'),
('2026-09-24', '추석 연휴'),
('2026-09-25', '추석'),
('2026-09-26', '추석 연휴'),
('2026-10-03', '개천절'),
('2026-10-09', '한글날'),
('2026-12-25', '성탄절')
on conflict do nothing;
