use std::collections::HashMap;
use tracing::{event, instrument};

pub enum PaginationError {
    InvalidValue,
    ParsingError(std::num::ParseIntError),
    RangeError,
}

#[derive(Debug, Default)]
pub struct Pagination {
    pub offset: u32,
    pub limit: Option<u32>,
}

impl TryFrom<HashMap<String, String>> for Pagination {
    type Error = PaginationError;

    #[instrument]
    fn try_from(value: HashMap<String, String>) -> Result<Self, Self::Error> {
       
        if value.contains_key("offset") && value.contains_key("limit") {
            event!(name: "pagination", tracing::Level::INFO, pagination = true);
            let offset = value
                .get("offset")
                .ok_or(PaginationError::InvalidValue)?
                .parse::<u32>()
                .map_err(PaginationError::ParsingError)?;

            let limit = match value.get("limit") {
                Some(val) => Some(val.parse::<u32>().map_err(PaginationError::ParsingError)?),
                None => Some(0),
            };
            Ok(Pagination { offset, limit })
        } else {
           
            Ok(Pagination::default())
        }
    }
}
