% sample structure array to store the credentials
creds = struct('ConsumerKey','MaArQ7vpx0XTWYkdDXdhP1fWL',...
    'ConsumerSecret','STFmMlXB4fMa5JdlViHkGLuar3oExzU2S4O0Ei39KAbktOX19C',...
    'AccessToken','948758986366451712-jtnWBfE9H4QnYIHee85F95NYv31njeq',...
    'AccessTokenSecret','gjTr2FXgn6eFgI7he2HkK6efWzeer3J7XN1q1LZXNklNl');
%    API_key = 'MaArQ7vpx0XTWYkdDXdhP1fWL'
%    API_Secret_Key = 'STFmMlXB4fMa5JdlViHkGLuar3oExzU2S4O0Ei39KAbktOX19C'
%    Bearer Token = 'AAAAAAAAAAAAAAAAAAAAAMuiPQEAAAAADAongDVH0JYIVc2qrx8UuMWptmI%3DdW1kszkFzY0wYmsHdcFdlko9bwXkUddU7QaDvs1KqisIQOdtAd'
%    AccessToken = '948758986366451712-jtnWBfE9H4QnYIHee85F95NYv31njeq'
%    AccessTokenSecret = 'gjTr2FXgn6eFgI7he2HkK6efWzeer3J7XN1q1LZXNklNl'

% set up a Twitty object
addpath twitty_1.1.1; % Twitty
addpath parse_json; % Twitty's default json parser
addpath jsonlab-2.0; % I prefer JSONlab, however.
% load('creds.mat') % load my real credentials
tw = twitty(creds); % instantiate a Twitty object
tw.jsonParser = @loadjson; % specify JSONlab as json parser

% search for English tweets that mention 'india' and 'china'
india = tw.search('india','count',100,'include_entities','true','lang','en');
china = tw.search('china','count',100,'include_entities','true','lang','en');
both = tw.search('india china','count',100,'include_entities','true','lang','en');
% Twitty stores tweets in structure array created from the API response in JSON format.

% load supporting data for text processing
scoreFile = 'affinn-111.txt'; % Afinn is the simplest yet popular lexicons used for sentiment analysis developed by Finn Årup Nielsen.
stopwordsURL ='http://www.textfixer.com/resources/common-english-words.txt';

% load previously saved data
load indiachina.mat

% process the structure array with a utility method |extract|
[indiaUsers,indiaTweets] = processTweets.extract(india);
% compute the sentiment scores with |scoreSentiment|
indiaTweets.Sentiment = processTweets.scoreSentiment(indiaTweets,scoreFile,stopwordsURL);

% repeat the process for china
[chinaUsers,chinaTweets] = processTweets.extract(china);
chinaTweets.Sentiment = processTweets.scoreSentiment(chinaTweets,scoreFile,stopwordsURL);

% repeat the process for tweets containing both
[bothUsers,bothTweets] = processTweets.extract(both);
bothTweets.Sentiment = processTweets.scoreSentiment(bothTweets,scoreFile,stopwordsURL);

% calculate and print NSRs
% NSR = (Positive Tweets-Negative Tweets)/Total
indiaNSR = (sum(indiaTweets.Sentiment>=0)-sum(indiaTweets.Sentiment<0))/height(indiaTweets);
chinaNSR = (sum(chinaTweets.Sentiment>=0)-sum(chinaTweets.Sentiment<0))/height(chinaTweets);
bothNSR = (sum(bothTweets.Sentiment>=0)-sum(bothTweets.Sentiment<0))/height(bothTweets);
fprintf('india NSR  :  %.2f\n',indiaNSR)
fprintf('china NSR:  %.2f\n',chinaNSR)
fprintf('Both NSR    : %.2f\n\n',bothNSR)

% plot the sentiment histogram of two brands
binranges = min([indiaTweets.Sentiment; ...
    chinaTweets.Sentiment; ...
    bothTweets.Sentiment]): ...
    max([indiaTweets.Sentiment; ...
    chinaTweets.Sentiment; ...
    bothTweets.Sentiment]);
bincounts = [histc(indiaTweets.Sentiment,binranges)...
    histc(chinaTweets.Sentiment,binranges)...
    histc(bothTweets.Sentiment,binranges)];
figure
bar(binranges,bincounts,'hist')
legend('india','china','Both','Location','Best')
title('Sentiment Distribution of 100 Tweets')
xlabel('Sentiment Score')
ylabel('# Tweets')

% tokenize tweets with |tokenize| method of |processTweets|
[words, dict] = processTweets.tokenize(bothTweets,stopwordsURL);
% create a dictionary of unique words
dict = unique(dict);
% create a word count matrix
[~,tdf] = processTweets.getTFIDF(words,dict);

% plot the word count
figure
plot(1:length(dict),sum(tdf),'b.')
xlabel('Word Indices')
ylabel('Word Count')
title('Words contained in the tweets')
% annotate high frequency words
annotated = find(sum(tdf)>= 10);
jitter = 6*rand(1,length(annotated))-3;
for i = 1:length(annotated)
    text(annotated(i)+3, ...
        sum(tdf(:,annotated(i)))+jitter(i),dict{annotated(i)})
end



% Get the Profile of Top 5 Users
% Twitty also supports the 'users/show' API to retrieve user profile information.
% Let's get the profile of the top 5 users based on the follower count.
% sort the user table by follower count in descending order
[~,order] = sortrows(bothUsers,'Followers','descend');
% select top 5 users
top5users = bothUsers(order(1:5),[3,1,5]);
% add a column to store the profile
top5users.Description = repmat({''},height(top5users),1);
% retrieve user profile for each user
for i = 1:5
    userInfo = tw.usersShow('user_id', top5users.Id(i));
    if ~isempty(userInfo{1}.description)
        top5users.Description{i} = userInfo{1}.description;
    end
end
% print the result
disp(top5users(:,2:end))