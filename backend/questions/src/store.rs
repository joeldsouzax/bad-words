use crate::domains::questions::{Question, QuestionId};
use sqlx::postgres::PgRow;
use sqlx::Row;
use sqlx::{postgres::PgPoolOptions, PgPool};
use tracing::{event, instrument, Level};

pub struct DatabaseError(sqlx::Error);

#[derive(Debug, Clone)]
pub struct Store {
    pub connection: PgPool,
}

impl Store {
    #[instrument]
    pub async fn new(url: &str) -> Result<Self, DatabaseError> {
        let connection = PgPoolOptions::new()
            .max_connections(5)
            .connect(url)
            .await
            .map_err(|err| {
                
                DatabaseError(err)
            })?;
        Ok(Self { connection })
    }

    #[instrument]
    pub async fn get_questions(
        &self,
        offset: i32,
        limit: Option<i32>,
    ) -> Result<Vec<Question>, DatabaseError> {
        sqlx::query("select * from questions limit $1 offset $2")
            .bind(limit)
            .bind(offset)
            .map(|row: PgRow| Question {
                id: QuestionId(row.get("id")),
                title: row.get("title"),
                content: row.get("content"),
                tags: row.get("tags"),
            })
            .fetch_all(&self.connection)
            .await
            .map_err(|err| {
                event!(name: "store", Level::ERROR, "{:?}", err);
                DatabaseError(err)
            })
    }

    #[instrument]
    pub async fn get_question(&self, question_id: i32) -> Result<Question, DatabaseError> {
        sqlx::query("select id, title, content, tags from questions where id = $1")
            .bind(question_id)
            .map(|row: PgRow| Question {
                id: QuestionId(row.get("id")),
                title: row.get("title"),
                content: row.get("content"),
                tags: row.get("tags"),
            })
            .fetch_one(&self.connection)
            .await
            .map_err(|err| {
                event!(name: "store", Level::ERROR, "{:?}", err);
                DatabaseError(err)
            })
    }

    #[instrument]
    pub async fn update_question(
        &self,
        question_id: i32,
        question: Question,
    ) -> Result<Question, DatabaseError> {
        sqlx::query("update questions set title = $1, content = $2, tags = $3 where id = $4 returning id, title, content, tags")
            .bind(question.title)
            .bind(question.content)
            .bind(question.tags)
            .bind(question_id)
            .map(|row: PgRow| Question {
                id: QuestionId(row.get("id")),
                title: row.get("title"),
                content: row.get("content"),
                tags: row.get("tags")
            })
            .fetch_one(&self.connection)
            .await
            .map_err(|err| {
                event!(name: "store", Level::ERROR, "{:?}", err);
                DatabaseError(err)
            })
    }
}
