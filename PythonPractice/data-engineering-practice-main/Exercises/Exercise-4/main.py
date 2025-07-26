#import boto3
import glob


def main():
    # your code here
    #directory = '.\PythonPractice\data-engineering-practice-main\Exercises\Exercise-4' 
    txt_files = glob.glob('**\*.json', recursive=True)

    for file in txt_files:
        print(file)
    pass


if __name__ == "__main__":
    main()
