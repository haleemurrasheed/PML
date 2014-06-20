#Data loading

#setwd("./data")
#if (!file.exists("data")) {
#  dir.create("data")
#    }
#fileUrl <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
#download.file(fileUrl, destfile = "training.csv", method = "curl")


#fileUrl <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
#download.file(fileUrl, destfile = "test.csv", method = "curl")
#list.files()
train_data <- read.table("training.csv", sep = ",", header = TRUE)
test_data <- read.table("test.csv", sep = ",", header = TRUE)

names(train_data)
head(test_data)

dim(train_data)
dim(test_data)
# cleaning data (Removing NA's)
clean_train <- train_data[, colSums(is.na(train_data)) == 0]
clean_test <- test_data[, colSums(is.na(test_data)) == 0]
dim(clean_train)
dim(clean_test)

#discarding non useful variables

n_c_train_1 <- clean_train[, !grepl("X|user_name|timestamp|window", colnames(clean_train))]
n_c_test_1 <- clean_test[, !grepl("X|user_name|timestamp|window", colnames(clean_test))]
dim(n_c_train_1)
dim(n_c_test_1)

n_c_train_2 <- n_c_train_1[, !grepl("^max|^min|^ampl|^var|^avg|^stdd|^ske|^kurt", colnames(n_c_train_1))]
n_c_test_2 <- n_c_test_1[, !grepl("^max|^min|^ampl|^var|^avg|^stdd|^ske|^kurt", colnames(n_c_test_1))]
dim(n_c_train_2)
dim(n_c_test_2)

#Cross validation (70% training and 30% validation)
set.seed(23222)

library(caret)
in_train <- createDataPartition(y = n_c_train_2$classe, p = 0.7, list = FALSE)
train <- n_c_train_2[in_train, ]
train_valid <- n_c_train_2[-in_train, ]
n_c_test <- n_c_test_2

# Plots

train_corr <- cor(train[, -53])
heatmap(train_corr)
library(corrplot)
corrplot(train_corr, method = "color")

# Most predictors do not exhibit a high degree of correlation, however some variables are highly correlated.

h_c <- abs(train_corr)
diag(h_c) <- 0
h_corr <- which(h_c > 0.8, arr.ind = TRUE)
for (i in 1:nrow(h_corr)) {
  print(names(train)[h_corr[i, ]])
}

# Solution : use PCA to pick the combination of predictors that captures the most information possible (benefits : reduced number of predictors and reduced noise).

train_pca <- preProcess(train[, -53], method  = "pca", thresh = 0.95) # 0.9
train_pca_1 <- predict(train_pca, train[, -53])
valid_pca <- predict(train_pca, train_valid[, -53])
test_pca <- predict(train_pca, n_c_test[, -53])
print(train_pca)

# Use of random forests We chose to specify the use of a cross validation method when applying the random forest routine in the 'trainControl()' parameter. Without specifying this, the default method (bootstrapping) would have been used. The bootstrapping method seemed to take a lot longer to complete, while essentially producing the same level of 'accuracy'.

mod <- train(train$classe ~ ., method = "rf", data = train_pca_1, trControl = trainControl(method = "cv", 5)) # 5
mod

# We now review the relative importance of the resulting principal components of the trained model, 'modelFit'.

varImpPlot(mod$finalModel, sort = TRUE)

# Cross validation

pred_valid <- predict(mod, valid_pca)
confusionMatrix(train_valid$classe, pred_valid)

# Out of sample error

OoSE <- 1 - as.numeric(confusionMatrix(train_valid$classe, pred_valid)$overall[1])

# Performance on test dataset (Correct values : "B" "A" "B" "A" "A" "E" "D" "B" "A" "A" "B" "C" "B" "A" "E" "E" "A" "B" "B" "B")

pred_test <- predict(mod, test_pca)

ans <- c("B", "A", "B", "A", "A", "E", "D", "B", "A", "A", "B", "C", "B", "A", "E", "E", "A", "B", "B", "B")
answer <- factor(ans)
answer == pred_test

