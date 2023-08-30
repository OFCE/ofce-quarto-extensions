azure_url ="https://xxxx.blob.core.windows.net/xxxx"
azure_jeton = "sp=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

bd <- pins::board_azure(
  AzureStor::storage_container(
    azure_url,
    sas = azure_jeton))

bd_hash <- function(obj) pins::pin_meta(bd, obj)$pin_hash
bd_read <- function(obj) pins::pin_read(bd, obj)

bd_write <- function(obj, name=NULL, title=NULL, description=NULL, metadata = NULL, tags=NULL, versioned=NULL) {
  if(is.null(name))
    name <- rlang::as_name(rlang::enquo(obj))
  pins::pin_write(board = bd,
                  x = obj,
                  name = name, 
                  title = title,
                  description = description,
                  metadata = metadata,
                  tags = tags,
                  versioned = versioned,
                  type = "qs")
}