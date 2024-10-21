create table if not exists answers (
id serial primary key,
content text not null,
created_on timestamp not null default now(),
corresponding_question_id integer references questions
);
