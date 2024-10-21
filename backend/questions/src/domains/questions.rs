#[derive(Debug, Clone)]
pub struct QuestionId(pub i32);

#[derive(Debug, Clone)]
pub struct Question {
    pub id: QuestionId,
    pub title: String,
    pub content: String,
    pub tags: Option<Vec<String>>,
}
