slido-cli
=========

A CLI toolbox to fetch [Slido](https://www.sli.do/) questions, vote for a question & revoke vote for a question.

### Dependency

- Bash
- cURL
- [jq](https://stedolan.github.io/jq/)
- [Puppeteer](https://github.com/GoogleChrome/puppeteer)

### Installation

- Install Puppeteer

```
npm i puppeteer --ignore-scripts
```

- Install jq: [link](https://stedolan.github.io/jq/download/)

### How to use


#### fetch-slido-token

First, change chrome app path in the script:

```
const chrome = '<path_to_your_chrome_browser>'
```

This script can fetch event uuid and user auth token of a Slido event.

```
Usage:
~$ node fetch-slido-token.js '<slido_question_list_url>'
```

For example, get user auth token of **GoT Last Season** Slido event:

```
~$ node fetch-slido-token.js 'https://app.sli.do/event/9duokmyd/live/questions'
"4c349204-385b-49a7-a130-f91a2e243e49,5910aa95f67be997fd5448373263ee78352c0db8"
```

The output contains 2 parts:

- Event uuid: `4c349204-385b-49a7-a130-f91a2e243e49`
- User auth token: `5910aa95f67be997fd5448373263ee78352c0db8`

#### show-questionlist.sh

This script can show the list of question of one specific Slido event.

```
Usage:
  ./show-questionlist.sh -i <event_uuid> -t <auth_token> [-n <nb_of_questions> -o [top|newest]]

Options:
  -i             Event uuid
  -t             User auth token
  -n             (optional) List max. number of questions, default value: 30
  -o             (optional) Sort by "top" or "newest", default value: top
  -h, --help     Display this help message
```

For example, get all questions of **GoT Last Season** Slido event:

```
~$ ./show-questionlist.sh -i '4c349204-385b-49a7-a130-f91a2e243e49' -t '5910aa95f67be997fd5448373263ee78352c0db8' -o 'newest'
...
{
  "author": {},
  "attrs": {},
  "type": "Question",
  "event_question_id": 8316368,
  "event_id": 890862,
  "event_section_id": 1027828,
  "text": "Who kills the Night King?",
  "is_public": true,
  "is_answered": false,
  "is_highlighted": false,
  "is_anonymous": true,
  "is_bookmarked": false,
  "score": 0,
  "score_positive": 0,
  "score_negative": 0,
  "date_published": null,
  "date_highlighted": null,
  "path": "/questions",
  "date_created": "2019-03-06T14:23:20.000Z",
  "date_updated": "2019-03-06T14:23:20.000Z",
  "date_deleted": null,
  "labels": [],
  "pinned_replies": []
},
...
```

This is how you can get `event_question_id`.

#### vote-question.sh

This script can vote or revoke vote of a specific question.

```
Usage:
  ./vote_question.sh -i <event_uuid> -t <auth_token> -q <question_id> [-r]

Options:
  -i             Event uuid
  -t             User auth token
  -q             Question id
  -r             (optional) Revoke vote
  -h, --help     Display this help message
```

For example, let's vote for the question **Who kills the Night King?**, event_question_id is 8316368:

```
~$ ./vote-question.sh -i '4c349204-385b-49a7-a130-f91a2e243e49' -t '5910aa95f67be997fd5448373263ee78352c0db8' -q 8316368
```

If you want to revoke your vote, same command plus `-r`:

```
~$ ./vote-question.sh -i '4c349204-385b-49a7-a130-f91a2e243e49' -t '5910aa95f67be997fd5448373263ee78352c0db8' -q 8316368 -r
```

:warning: The scores in response data from vote-question.sh are not accurate. Because they're delayed from Slido server. To get the correct scores, use command `show-questionlist.sh`.

### To be, or not to be Evil? :performing_arts:

Slido doesn't limit IP address for generating user token. Technically, it's possible to get as many tokens as possible on one machine. And 1 token means 1 vote. Therefore, this makes vote result manipulation easier. The workflow is described as below.

#### Generate tokens

Generate 20 tokens and save them in `auth.conf` file:

```
~$ for ((i = 0; i < 20; i++)); do echo $i; node fetch-slido-token.js 'https://app2.sli.do/event/<certain_event>/live/questions' >> auth.conf; done
```

#### Get question id

```
~$ ./show-questionlist.sh -i <event_uuid> -t <auth_token> | grep -B 3 -i <question_text> | grep event_question_id
```

#### Massive voting: +20 likes

```
~$ while IFS='' read -r line || [[ -n "$line" ]]; do ./vote-question.sh -i "${line%,*}" -t "${line##*,}" -q <question_id>; done < auth.conf
```

#### One more thing?

Btw, script for lazy human: `bot-vote.sh`.
