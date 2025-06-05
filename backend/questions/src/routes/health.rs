use tracing::{event, instrument, Level};
use warp::{http::StatusCode, Rejection, Reply};

#[instrument]
pub async fn health_check() -> Result<impl Reply, Rejection> {
    
    Ok(warp::reply::with_status("healthy", StatusCode::OK))
}
