#!/usr/bin/env python3
"""Offline structural validation for bundled QuisquisLingo Course Model v3 JSON."""
from __future__ import annotations
import json, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
COURSES=ROOT/'assets'/'courses'
INTERACTIONS={'select','input','arrange','match'}
EVALUATIONS={'selected_items','text_match','ordered_items','matched_items'}
CONTENT_KINDS={'exercise','presentation','explanation','example','vocabulary','text','image','audio','dialogue'}

def validate(path:Path)->list[str]:
    data=json.loads(path.read_text(encoding='utf-8')); issues=[]; ids=set(); pending_refs=[]
    if data.get('formatVersion')!=3:issues.append('root: formatVersion must be 3')
    def add_id(value,where):
        if not isinstance(value,str) or not value.strip():issues.append(f'{where}: missing id');return
        if value in ids:issues.append(f'{where}: duplicate id {value}')
        ids.add(value)
    def validate_content(c,where):
        add_id(c.get('id'),where)
        kind=c.get('kind')
        if kind not in CONTENT_KINDS:issues.append(f'{where}: unknown Content kind {kind}')
        refs=c.get('sourceRefs',[])
        if refs is not None and not isinstance(refs,list):issues.append(f'{where}: sourceRefs must be a list')
        elif isinstance(refs,list):
            for ref in refs:
                if not isinstance(ref,str) or not ref.strip():issues.append(f'{where}: invalid sourceRef')
                else:pending_refs.append((ref,where))
        if kind=='exercise':
            e=c.get('exercise')
            if not isinstance(e,dict):issues.append(f'{where}: exercise payload missing');return
            inter=e.get('interaction');ev=e.get('evaluation')
            if not isinstance(inter,dict) or inter.get('kind') not in INTERACTIONS:issues.append(f'{where}: invalid interaction')
            if not isinstance(ev,dict) or ev.get('kind') not in EVALUATIONS:issues.append(f'{where}: invalid evaluation')
            items=(inter or {}).get('items',[]) if isinstance(inter,dict) else []
            if items is None:items=[]
            if not isinstance(items,list):issues.append(f'{where}: interaction.items must be a list');items=[]
            item_ids=[]
            for it in items:
                iid=it.get('id') if isinstance(it,dict) else None
                if not iid:issues.append(f'{where}: Item missing id')
                elif iid in item_ids:issues.append(f'{where}: duplicate Item id {iid}')
                item_ids.append(iid)
            if isinstance(ev,dict):
                for key in ('correctItemIds','correctOrder'):
                    values=ev.get(key,[])
                    if not isinstance(values,list):issues.append(f'{where}: {key} must be a list');continue
                    for iid in values:
                        if iid not in item_ids:issues.append(f'{where}: {key} references missing Item {iid}')
                pairs=ev.get('pairs',[])
                if not isinstance(pairs,list):issues.append(f'{where}: pairs must be a list')
                else:
                    for pair in pairs:
                        if not isinstance(pair,list) or len(pair)!=2 or any(i not in item_ids for i in pair):issues.append(f'{where}: invalid matched_items pair')
                if ev.get('kind')=='text_match':
                    accepted=ev.get('acceptedAnswers')
                    if not isinstance(accepted,list) or not any(isinstance(v,str) and v.strip() for v in accepted):
                        issues.append(f'{where}: text_match requires non-empty acceptedAnswers')
            if isinstance(inter,dict) and inter.get('kind')=='input' and isinstance(ev,dict) and ev.get('kind')!='text_match':
                issues.append(f'{where}: input interaction must use text_match evaluation')
        if kind=='presentation':
            p=c.get('presentation');acts=((p or {}).get('completion') or {}).get('actions',[]) if isinstance(p,dict) else []
            if not {'understood','review_later'}.issubset(set(acts)):issues.append(f'{where}: presentation must support understood and review_later')

    chapters=data.get('chapters')
    if not isinstance(chapters,list):return issues+['root: chapters must be a list']
    for ci,ch in enumerate(chapters,1):
        if not isinstance(ch,dict):issues.append(f'chapter {ci}: must be an object');continue
        add_id(ch.get('id'),f'chapter {ci}')
        if 'guidebook' in ch:issues.append(f'chapter {ci}: Chapter-level guidebook is not allowed in Course Model v3')
        topics=ch.get('topics',[])
        if not isinstance(topics,list):issues.append(f'chapter {ci}: topics must be a list');continue
        assessments=0
        for ti,t in enumerate(topics,1):
            if not isinstance(t,dict):issues.append(f'chapter {ci} topic {ti}: must be an object');continue
            where_topic=f'chapter {ci} topic {ti}'
            add_id(t.get('id'),where_topic)
            role=t.get('role','learning')
            if role=='assessment':
                assessments+=1
                if 'guidebook' in t:issues.append(f'{where_topic}: assessment Topic must not contain a guidebook')
                a=t.get('assessment')
                if not isinstance(a,dict):issues.append(f'{where_topic}: assessment config missing')
                elif a.get('purpose')=='skip_test':
                    count=((a.get('selection') or {}).get('count'))
                    if count != 25:issues.append(f'{where_topic}: Language Duel selection count must be 25')
                    if 'evaluation' in a and isinstance(a.get('evaluation'),dict) and 'passThreshold' in a.get('evaluation',{}):issues.append(f'{where_topic}: Language Duel must not use passThreshold')
            else:
                if not t.get('imageAsset'):issues.append(f'{where_topic}: learning Topic has no imageAsset')
                gb=t.get('guidebook')
                if not isinstance(gb,dict):issues.append(f'{where_topic}: learning Topic guidebook missing')
                else:
                    gc=gb.get('content')
                    if not isinstance(gc,list):issues.append(f'{where_topic}: guidebook.content must be a list')
                    elif not gc:issues.append(f'{where_topic}: guidebook.content is empty')
                    else:
                        for gi,c in enumerate(gc,1):
                            if not isinstance(c,dict):issues.append(f'{where_topic} guidebook content {gi}: must be an object')
                            else:validate_content(c,f'{where_topic} guidebook content {gi}')
            rounds=t.get('rounds',[])
            if not isinstance(rounds,list):issues.append(f'{where_topic}: rounds must be a list');continue
            for ri,r in enumerate(rounds,1):
                if not isinstance(r,dict):issues.append(f'{where_topic} round {ri}: must be an object');continue
                round_where=f'{where_topic} round {ri}'
                add_id(r.get('id'),round_where)
                content=r.get('content')
                if not isinstance(content,list):issues.append(f'{round_where}: content must be a list');continue
                if role!='assessment' and not content:issues.append(f'{round_where}: empty Round')
                if role!='assessment' and ri==1 and content:
                    first=content[0]
                    if not isinstance(first,dict) or first.get('role')!='topic_intro' or first.get('kind')=='exercise':
                        issues.append(f'{round_where}: first Content must be a non-exercise topic_intro')
                for xi,c in enumerate(content,1):
                    where=f'{round_where} content {xi}'
                    if not isinstance(c,dict):issues.append(f'{where}: must be an object')
                    else:validate_content(c,where)
        if assessments!=1:issues.append(f'chapter {ci}: expected exactly one assessment Topic, found {assessments}')
    for ref,where in pending_refs:
        if ref not in ids:issues.append(f'{where}: sourceRefs references missing Content {ref}')
    return issues

def main()->int:
    total=0
    files=sorted(COURSES.glob('*.json'))
    if not files:
        print('No bundled course JSON files found.')
        return 1
    for path in files:
        issues=validate(path);total+=len(issues);print(f"{path.name}: {'OK' if not issues else f'{len(issues)} issue(s)'}")
        for i in issues:print('  -',i)
    return 1 if total else 0
if __name__=='__main__':sys.exit(main())
