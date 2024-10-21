use crate::domains::questions::QuestionId;

#[derive(Debug, Clone)]
pub struct AnswerId(pub i32);

#[derive(Debug, Clone)]
pub struct Answer {
    pub id: AnswerId,
    pub content: String,
    pub question_id: QuestionId,
}
