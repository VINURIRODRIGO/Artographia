##Imports
import config
import comet_ml
import os
import numpy as np
import cv2
import random
import tensorflow as tf
from sklearn.model_selection import train_test_split
from keras.utils import to_categorical
from keras.applications.inception_v3 import InceptionV3
from keras.applications import MobileNetV2
from keras.layers import Input, Flatten, Dense, Dropout, concatenate
from keras.models import Model
from keras.optimizers import SGD
from keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt

from sklearn.metrics import confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns
from dataclasses import dataclass

# Ensure deterministic behavior on GPU (if available)
if len(tf.config.list_physical_devices('GPU')) > 0:
    print('GPU name: ', tf.config.list_physical_devices('GPU')[0].name)
    print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))

"""###Connect to the Google Drive"""

drive.mount('/content/drive')

"""###Define parameters"""

@dataclass(frozen=True)
class DatasetConfiguration:
  IMG_HEIGHT = 224
  IMG_WIDTH = 224
  CHANNELS = 3
  DATASET_PATH = '/content/drive/MyDrive/handpd_dataset' # Define the path to the dataset folder
  RANDOM_STATE = 42

@dataclass(frozen=True)
class TrainingConfiguration:
  BATCH_SIZE = 20
  EPOCHS = 35
  DROPOUT= 0.3
  INCEPTIONV3_UNFREEZING_LAYERS = 20
  MOBILENETV2_UNFREEZING_LAYERS = 10
  FIRST_INPUT_UNIT = 256
  OUTPUT_UNIT = 2
  INPUT_ACTIVATION = 'tanh'
  OUTPUT_ACTIVATION = 'sigmoid'
  FINE_TUNE_LR = 0.001

@dataclass(frozen=True)
class CometMLConfiguration:
  API_KEY = config.api_key
  PROJECT_NAME = "artographia-v1"
  WORKSPACE = "vinurirodrigo"

@dataclass(frozen=True)
class AugmentationConfiguration:
  ROTATION_RANGE = 20
  WIDTH_SHIFT_RANGE = 0.2
  HEIGHT_SHIFT_RANGE = 0.2
  SHEAR_RANGE = 0.2
  ZOOM_RANGE = 0.2
  FILL_MODE = 'nearest'
  #check seed, regularization, saprcityconstrain

# Set a random seed for reproducibility
np.random.seed(DatasetConfiguration.RANDOM_STATE)
random.seed(DatasetConfiguration.RANDOM_STATE)
tf.random.set_seed(DatasetConfiguration.RANDOM_STATE)

# Create an experiment with the api key
experiment = comet_ml.Experiment(
    api_key = CometMLConfiguration.API_KEY,
    project_name= CometMLConfiguration.PROJECT_NAME,
    workspace= CometMLConfiguration.WORKSPACE,
    auto_param_logging=True,
    auto_metric_logging=True,
    auto_histogram_weight_logging=True,
    auto_histogram_gradient_logging=True,
    auto_histogram_activation_logging=True,
    auto_histogram_epoch_rate=True,
)

"""##Loading the Dataset and Preprocessing"""

parameters = {
    "batch_size": TrainingConfiguration.BATCH_SIZE,
    "epochs": TrainingConfiguration.EPOCHS,
    "learning_rate":TrainingConfiguration.FINE_TUNE_LR,
    "GoogLeNet_unfreeze_layers": TrainingConfiguration.INCEPTIONV3_UNFREEZING_LAYERS,
    "MobileNetV2_unfreeze_layers": TrainingConfiguration.MOBILENETV2_UNFREEZING_LAYERS,
    "optimizer": "SGD", #SGD, // refer for more details: chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://www.researchgate.net/profile/Pedram-Khatamino/publication/334168335_A_Deep_Learning-CNN_Based_System_for_Medical_Diagnosis_An_Application_on_Parkinson%27s_Disease_Handwriting_Drawings/links/5dffac1392851c836493b082/A-Deep-Learning-CNN-Based-System-for-Medical-Diagnosis-An-Application-on-Parkinsons-Disease-Handwriting-Drawings.pdf
    "loss": "binary_crossentropy",
    "validation_split": 0.1,
}

experiment.log_parameters(parameters)

# Define a function to load and preprocess images
data = []
labels = []
def load_and_preprocess_images(path, label):
  # Initialize empty lists to store data and labels
    for filename in sorted(os.listdir(path)):
        if filename.endswith('.jpg'):
            # Load the image
            img = cv2.imread(os.path.join(path, filename))
            experiment.log_image(os.path.join(path, filename), filename,overwrite=False, image_format="jpg")
            # Resize the image to a consistent size (e.g., 224x224)
            img = cv2.resize(img, (DatasetConfiguration.IMG_HEIGHT, DatasetConfiguration.IMG_WIDTH))
            # Normalize(min-max scaling) pixel values to be between 0 and 1
            img = img / 255.0
            # Append the image data and label to the lists
            data.append(img)
            labels.append(label)

# Load and preprocess images from the 'HealthySpiral' folder
load_and_preprocess_images(os.path.join(DatasetConfiguration.DATASET_PATH,'ResizeHealthySpiral'), label=0)

# Load and preprocess images from the 'PatientSpiral' folder
load_and_preprocess_images(os.path.join(DatasetConfiguration.DATASET_PATH, 'ResizePatientSpiral'), label=1)

# Function to display an image from the dataset
def display_image(image):
    plt.imshow(image)
    plt.title("Sample Image")
    plt.axis('off')  # Hide axis values
    plt.show()

# Display an image from the PD class
image_index = 0
display_image(data[image_index])

# Convert lists to NumPy arrays
data = np.array(data)
labels = np.array(labels)

"""###Splitting the Dataset"""

# Split the dataset into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(data, labels, test_size=0.2, random_state=DatasetConfiguration.RANDOM_STATE)
# Convert labels to one-hot encoding
y_train = to_categorical(y_train, num_classes=2)
y_test = to_categorical(y_test, num_classes=2)

"""###Concatenating Features from Base Models"""

# Define a single input layer
INPUT_LAYER = Input(shape=(DatasetConfiguration.IMG_HEIGHT, DatasetConfiguration.IMG_WIDTH, DatasetConfiguration.CHANNELS))

#Create the GoogLeNet base model
base_model_inception = InceptionV3(weights='imagenet', include_top=False, input_tensor= INPUT_LAYER)

#Create the MobileNetV2 base model
base_model_mobilenet = MobileNetV2(weights='imagenet', include_top=False, input_tensor=INPUT_LAYER)

# Freeze the layers of the pre-trained models
for layer in base_model_inception.layers:
    layer.trainable = False
for layer in base_model_mobilenet.layers:
    layer.trainable = False

"""##Feature Extraction and Concatenation"""

# Remove the top classification layers from the base models
inception_features = Flatten()(base_model_inception.layers[-1].output)
mobilenet_features = Flatten()(base_model_mobilenet.layers[-1].output)

# Concatenate the output features from both models
merged_features = concatenate([inception_features, mobilenet_features])

"""## Fine Tuning"""

print("Number of GoogLeNet Layers ", len(base_model_inception.layers))
print("Number of MobileNetV2 Layers ",len(base_model_mobilenet.layers))
# Fine-tuning by unfreezing layers and training
for layer in base_model_inception.layers[-TrainingConfiguration.INCEPTIONV3_UNFREEZING_LAYERS:]:
    layer.trainable = True
for layer in base_model_mobilenet.layers[-TrainingConfiguration.MOBILENETV2_UNFREEZING_LAYERS:]:
    layer.trainable = True

"""## Adding new Layers to the model"""

# Add a classification layer
predictions = Dense(TrainingConfiguration.FIRST_INPUT_UNIT, TrainingConfiguration.INPUT_ACTIVATION)(merged_features)
predictions = Dropout(TrainingConfiguration.DROPOUT)(predictions)
output = Dense(TrainingConfiguration.OUTPUT_UNIT, TrainingConfiguration.OUTPUT_ACTIVATION)(predictions)

# Create the custom hybrid model
hybrid_model = Model(inputs=INPUT_LAYER, outputs=output)

"""## Data Augmentation"""

# Data augmentation
datagen_inception = ImageDataGenerator(
    rotation_range = AugmentationConfiguration.ROTATION_RANGE,
    width_shift_range = AugmentationConfiguration.WIDTH_SHIFT_RANGE,
    height_shift_range = AugmentationConfiguration.WIDTH_SHIFT_RANGE,
    shear_range = AugmentationConfiguration.SHEAR_RANGE,
    zoom_range = AugmentationConfiguration.ZOOM_RANGE,
    horizontal_flip = True,
    fill_mode = AugmentationConfiguration.FILL_MODE,
    )
# Fit the data augmentation generator to the training data
datagen_inception.fit(X_train)  # Set the seed for reproducibility

"""## Compile the hybrid model"""

hybrid_model.compile(optimizer=SGD(learning_rate=TrainingConfiguration.FINE_TUNE_LR),
    loss='binary_crossentropy',
    metrics=['accuracy'])

hybrid_model.summary()

"""## Train the hybrid model"""

history = hybrid_model.fit(datagen_inception.flow(X_train, y_train, batch_size=TrainingConfiguration.BATCH_SIZE),
                           steps_per_epoch=len(X_train) / TrainingConfiguration.BATCH_SIZE,
                           epochs=TrainingConfiguration.EPOCHS,
                           validation_data=(X_test, y_test))

"""###Convert the model architecture to JSON and save it to the Comet ML"""

model_architecture_json = hybrid_model.to_json()

# Log the model architecture to Comet as text
experiment.log_text("Hybrid Model Architecture", model_architecture_json)

"""### Evaluate the model"""

# Evaluate the model (minor adjustments to evaluation metrics)
evaluation_metrics = hybrid_model.evaluate(X_test, y_test, verbose=0)
evaluation_loss = evaluation_metrics[0]
accuracy = evaluation_metrics[1]  # Use accuracy from evaluation

"""#### Plot the confusion matrix"""

# Make predictions on the test dataset
y_pred = hybrid_model.predict(X_test)

# Convert one-hot encoded predictions to class labels
y_pred_labels = np.argmax(y_pred, axis=1)
y_true_labels = np.argmax(y_test, axis=1)

# Calculate the confusion matrix
confusion_mtx = confusion_matrix(y_true_labels, y_pred_labels)

# Log the confusion matrix to Comet
experiment.log_confusion_matrix(matrix=confusion_mtx)
plt.figure(figsize=(8, 6))
sns.heatmap(confusion_mtx, annot=True, fmt='d', cmap='Blues',
            xticklabels=['Healthy', 'Patient'], yticklabels=['Healthy', 'Patient'])
plt.xlabel('Predicted')
plt.ylabel('True')
plt.title('Confusion Matrix')
plt.show()

# Calculate metrics (accuracy, precision, recall, f1_score) from the confusion matrix
total_samples = np.sum(confusion_mtx)
accuracy = np.sum(np.diag(confusion_mtx)) / total_samples
precision = confusion_mtx[1, 1] / (confusion_mtx[1, 1] + confusion_mtx[0, 1])
recall = confusion_mtx[1, 1] / (confusion_mtx[1, 1] + confusion_mtx[1, 0])
f1_score = 2 * (precision * recall) / (precision + recall)
evaluation_metrics = hybrid_model.evaluate(X_test, y_test, verbose=0)
evaluation_loss = evaluation_metrics[0]

# Print the evaluation results
print("loss_mtx", evaluation_loss)
print("accuracy_mtx", accuracy)
print("f1_score_mtx", f1_score)
print("precision_mtx", precision)
print("recall_mtx", recall)

# Generate a classification report
classification_rep = classification_report(y_true_labels, y_pred_labels, target_names=['Healthy', 'Patient'],
                                           output_dict=True)

# Extract metrics from classification report
precision_healthy = classification_rep['Healthy']['precision']
recall_healthy = classification_rep['Healthy']['recall']
f1_healthy = classification_rep['Healthy']['f1-score']

precision_patient = classification_rep['Patient']['precision']
recall_patient = classification_rep['Patient']['recall']
f1_patient = classification_rep['Patient']['f1-score']

# Log the extracted metrics to Comet
experiment.log_metric("precision_healthy", precision_healthy)
experiment.log_metric("recall_healthy", recall_healthy)
experiment.log_metric("f1_healthy", f1_healthy)

experiment.log_metric("precision_patient", precision_patient)
experiment.log_metric("recall_patient", recall_patient)
experiment.log_metric("f1_patient", f1_patient)

print("Classification Report:\n", classification_rep)

"""##Save the Model Architecture to the Comet ML"""

hybrid_model.save('parkinsons_detection_model.keras')

# Save the trained model to Comet
experiment.log_model(
    name= "parkinsons_detection_model",
    file_or_folder="parkinsons_detection_model.keras",
    overwrite=False  # Set to True to overwrite any existing model with the same name
)

# Load your existing trained model
hybrid_model = tf.keras.models.load_model('parkinsons_detection_model.keras')

# Define a function to convert the model to a lightweight format (e.g., TensorFlow Lite)
def convert_to_lite_model(original_model):
    converter = tf.lite.TFLiteConverter.from_keras_model(original_model)
    converter.optimizations = [tf.lite.Optimize.OPTIMIZE_FOR_SIZE]
    tflite_model = converter.convert()
    return tflite_model

# Convert the model to a lightweight format
lite_model = convert_to_lite_model(hybrid_model)
tf.lite.experimental.Analyzer.analyze(model_content=lite_model)

# Save the lightweight model to a file
lite_model_filename = 'parkinsons_detection_model_lite.tflite'
with open(lite_model_filename, 'wb') as f:
    f.write(lite_model)

# Log the lightweight model to Comet ML with a custom filename
experiment.log_asset(file_data=lite_model_filename, file_name='lite_model.tflite')

"""## End the Comet ML experiment"""

experiment.end()

experiment.display(tab="confusion-matrices")