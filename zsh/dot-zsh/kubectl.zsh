# kubectl
if test -e $(which kubectl); then
 source <(kubectl completion zsh);

 alias kubectlnsls="kubectl config view | grep namespace:"

 function awslogin() {
  case "$1" in
  "hitrecord")
      aws --profile hitrecord --region us-east-1 ecr get-login-password | docker login --username AWS --password-stdin 088909061057.dkr.ecr.us-east-1.amazonaws.com
      ;;
  "jason" | "jason-admin")
      aws --profile jason-admin --region us-west-2 ecr get-login-password | docker login --username AWS --password-stdin 191669008337.dkr.ecr.us-west-2.amazonaws.com/
      ;;
  *)
      echo "pick jason or hitrecord"
      ;;
  esac
 }

#  function kubectlns() {
#    kubectl config set-context $(kubectl config current-context) --namespace=$1
#  }
fi
