create extension if not exists "pgcrypto";

create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    display_name text,
    created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.brands (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    name text not null,
    normalized_name text not null,
    created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.polishes (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    brand_id uuid references public.brands (id) on delete set null,
    name text not null,
    normalized_name text not null,
    color_family text not null check (color_family in ('vermelho', 'rosa', 'nude', 'azul', 'verde', 'preto', 'branco', 'roxo', 'prata', 'dourado', 'multicolorido')),
    tone text not null check (tone in ('claro', 'medio', 'escuro')),
    finish text not null check (finish in ('cremoso', 'cintilante', 'glitter', 'transparente', 'metalico')),
    notes text,
    photo_path text,
    is_favorite boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.tags (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    name text not null,
    normalized_name text not null,
    created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.polish_tags (
    polish_id uuid not null references public.polishes (id) on delete cascade,
    tag_id uuid not null references public.tags (id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now()),
    primary key (polish_id, tag_id)
);

create unique index if not exists brands_user_normalized_name_key
    on public.brands (user_id, normalized_name);

create unique index if not exists tags_user_normalized_name_key
    on public.tags (user_id, normalized_name);

create index if not exists polishes_user_normalized_name_idx
    on public.polishes (user_id, normalized_name);

create index if not exists polishes_user_brand_idx
    on public.polishes (user_id, brand_id);

create index if not exists polishes_user_classification_idx
    on public.polishes (user_id, color_family, tone, finish);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$$;

drop trigger if exists polishes_set_updated_at on public.polishes;

create trigger polishes_set_updated_at
before update on public.polishes
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.brands enable row level security;
alter table public.polishes enable row level security;
alter table public.tags enable row level security;
alter table public.polish_tags enable row level security;

create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "brands_all_own"
on public.brands
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "polishes_all_own"
on public.polishes
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "tags_all_own"
on public.tags
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "polish_tags_all_own"
on public.polish_tags
for all
using (
    exists (
        select 1
        from public.polishes p
        where p.id = polish_tags.polish_id
          and p.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.polishes p
        where p.id = polish_tags.polish_id
          and p.user_id = auth.uid()
    )
    and exists (
        select 1
        from public.tags t
        where t.id = polish_tags.tag_id
          and t.user_id = auth.uid()
    )
);

insert into storage.buckets (id, name, public)
values ('polish-photos', 'polish-photos', false)
on conflict (id) do nothing;

create policy "storage_select_own_polish_photos"
on storage.objects
for select
using (
    bucket_id = 'polish-photos'
    and auth.uid()::text = split_part(name, '/', 1)
);

create policy "storage_insert_own_polish_photos"
on storage.objects
for insert
with check (
    bucket_id = 'polish-photos'
    and auth.uid()::text = split_part(name, '/', 1)
);

create policy "storage_update_own_polish_photos"
on storage.objects
for update
using (
    bucket_id = 'polish-photos'
    and auth.uid()::text = split_part(name, '/', 1)
)
with check (
    bucket_id = 'polish-photos'
    and auth.uid()::text = split_part(name, '/', 1)
);

create policy "storage_delete_own_polish_photos"
on storage.objects
for delete
using (
    bucket_id = 'polish-photos'
    and auth.uid()::text = split_part(name, '/', 1)
);

