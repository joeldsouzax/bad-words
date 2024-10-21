#![warn(clippy::all)]

use tracing_subscriber::fmt::format::FmtSpan;
use warp::Filter;

mod domains;
mod routes;
mod store;

#[tokio::main]
async fn main() {
    // initialize tracing subscriber to capture tracing events.
    // get all env variables necessary to configure the application
    let log_level = std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into());
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:sphynx@0.0.0.0:5432/bad_words".into());
    let bad_words_api_key = std::env::var("BAD_WORDS_KEY").unwrap_or_else(|_| "".into());

    tracing_subscriber::fmt()
        .with_env_filter(log_level)
        .with_span_events(FmtSpan::CLOSE)
        .init();

    // database creation
    let store = store::Store::new(&database_url)
        .await
        .expect("Database connection is expected!!");

    sqlx::migrate!()
        .run(&store.clone().connection)
        .await
        .expect("Cannot run migration");

    // route handlers
    let health_check = warp::get()
        .and(warp::path("health"))
        .and(warp::path::end())
        .and_then(routes::health::health_check)
        .with(warp::trace(
            |info| tracing::info_span!("heath check method", method = %info.method(), path = %info.path(), id = %uuid::Uuid::new_v4()),
        ));

    let routes = health_check.with(warp::trace::request());
    // start the server
    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

// TODO: create sql connection and store and test database
