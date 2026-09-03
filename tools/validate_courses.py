#!/usr/bin/env python3
"""Offline structural validation for bundled QuisquisLingo Course Model v5 JSON."""
from __future__ import annotations
import base64, binascii, json, re, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
COURSES=ROOT/'assets'/'courses'
INTERACTIONS={'select','input','arrange','match'}
EVALUATIONS={'selected_items','text_match','ordered_items','matched_items'}
CONTENT_KINDS={'exercise','presentation','explanation','example','vocabulary','text','image','audio','dialogue'}
ROUND_VISUAL_TYPES={'listening','story','generic','test'}
PUBLICATION_STATES={'draft','published'}
LESSON_NUMBERING_MODES={'lesson','unit','topic','module','skill','chapter','stage','step','part','other','numberOnly','none'}
LESSON_ICON_STYLES={'monochrome','coloredLessonNumbers'}
LESSON_ICON_PATHS=set(re.findall(
    r"assets/lesson_icons/[a-z0-9_]+\.png",
    (ROOT/'lib'/'services'/'lesson_icon_catalog.dart').read_text(encoding='utf-8'),
))

def validate(path:Path)->list[str]:
    data=json.loads(path.read_text(encoding='utf-8')); issues=[]; ids=set(); pending_refs=[]
    if data.get('formatVersion')!=5:issues.append('root: formatVersion must be 5')
    if data.get('publicationState') not in PUBLICATION_STATES:issues.append('root: publicationState must be draft or published')
    if data.get('lessonNumberingMode') not in LESSON_NUMBERING_MODES:issues.append('root: lessonNumberingMode is missing or invalid')
    if data.get('defaultLessonIconStyle') not in LESSON_ICON_STYLES:issues.append('root: defaultLessonIconStyle is missing or invalid')
    if data.get('lessonNumberingMode')=='other' and (not isinstance(data.get('customLessonLabel'),str) or not data.get('customLessonLabel').strip()):issues.append('root: customLessonLabel is required for Other')
    if 'topics' in data:issues.append('root: legacy topics field is not allowed in Course Model v5')
    if 'chapters' in data:issues.append('root: chapters are not allowed in Course Model v5')
    if not isinstance(data.get('temporarySample'),bool):issues.append('root: temporarySample must be a boolean')
    lesson_icon_assets=data.get('lessonIconAssets',[])
    managed_icon_ids=set()
    if not isinstance(lesson_icon_assets,list):
        issues.append('root: lessonIconAssets must be a list')
        lesson_icon_assets=[]
    for index,asset in enumerate(lesson_icon_assets,1):
        where=f'lesson icon asset {index}'
        if not isinstance(asset,dict):issues.append(f'{where}: must be an object');continue
        asset_id=asset.get('assetId')
        if not isinstance(asset_id,str) or not re.fullmatch(r'[A-Za-z0-9_-]+',asset_id):issues.append(f'{where}: invalid assetId');continue
        if asset_id in managed_icon_ids:issues.append(f'{where}: duplicate assetId {asset_id}')
        managed_icon_ids.add(asset_id)
        encoded=asset.get('base64Png')
        try:png=base64.b64decode(encoded,validate=True) if isinstance(encoded,str) else b''
        except (binascii.Error,ValueError):png=b''
        if len(png)<24 or png[:8]!=b'\x89PNG\r\n\x1a\n' or png[12:16]!=b'IHDR':issues.append(f'{where}: invalid PNG')
        elif int.from_bytes(png[16:20],'big')!=256 or int.from_bytes(png[20:24],'big')!=256:issues.append(f'{where}: PNG must be 256x256')
    def add_id(value,where):
        if not isinstance(value,str) or not value.strip():issues.append(f'{where}: missing id');return
        if value in ids:issues.append(f'{where}: duplicate id {value}')
        ids.add(value)
    def validate_content(c,where):
        add_id(c.get('id'),where)
        if c.get('publicationState') not in PUBLICATION_STATES:issues.append(f'{where}: publicationState must be draft or published')
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

    lessons=data.get('lessons')
    if not isinstance(lessons,list):return issues+['root: lessons must be a list']
    for ti,t in enumerate(lessons,1):
        if not isinstance(t,dict):issues.append(f'lesson {ti}: must be an object');continue
        where_lesson=f'lesson {ti}'
        if 'id' in t or 'topicId' in t:issues.append(f'{where_lesson}: legacy identity field is not allowed')
        add_id(t.get('lessonId'),where_lesson)
        if t.get('publicationState') not in PUBLICATION_STATES:issues.append(f'{where_lesson}: publicationState must be draft or published')
        if 'role' in t:issues.append(f'{where_lesson}: role is not allowed in Course Model v5')
        if 'assessment' in t:issues.append(f'{where_lesson}: assessment is not allowed in Course Model v5')
        if 'imageAsset' in t:issues.append(f'{where_lesson}: obsolete Lesson imageAsset is not allowed in Course Model v5')
        section=t.get('section',False);section_name=t.get('sectionName')
        if not isinstance(section,bool):issues.append(f'{where_lesson}: section must be a boolean')
        elif section and (not isinstance(section_name,str) or not section_name.strip()):issues.append(f'{where_lesson}: sectionName is required when section is true')
        elif not section and isinstance(section_name,str) and section_name.strip():issues.append(f'{where_lesson}: sectionName must be absent when section is false')
        icon=t.get('themeIconAsset')
        if icon is not None:
            managed=re.fullmatch(r'course-assets/lesson-icons/([A-Za-z0-9_-]+)\.png',icon) if isinstance(icon,str) else None
            if managed:
                if managed.group(1) not in managed_icon_ids:issues.append(f'{where_lesson}: unresolved managed themeIconAsset: {icon}')
            elif not isinstance(icon,str) or not icon.startswith('assets/lesson_icons/') or not icon.lower().endswith('.png'):issues.append(f'{where_lesson}: invalid themeIconAsset path')
            elif icon not in LESSON_ICON_PATHS:issues.append(f'{where_lesson}: themeIconAsset is not in the canonical catalog: {icon}')
            elif not (ROOT/icon).is_file():issues.append(f'{where_lesson}: themeIconAsset does not exist: {icon}')
        gb=t.get('guidebook')
        if not isinstance(gb,dict):issues.append(f'{where_lesson}: Lesson guidebook missing')
        else:
            gc=gb.get('content')
            if not isinstance(gc,list):issues.append(f'{where_lesson}: guidebook.content must be a list')
            elif not gc:issues.append(f'{where_lesson}: guidebook.content is empty')
            else:
                for gi,c in enumerate(gc,1):
                    if not isinstance(c,dict):issues.append(f'{where_lesson} guidebook content {gi}: must be an object')
                    else:validate_content(c,f'{where_lesson} guidebook content {gi}')
        duel=t.get('duel')
        if not isinstance(duel,dict):issues.append(f'{where_lesson}: duel must be an object')
        else:
            add_id(duel.get('id'),f'{where_lesson} duel')
            if not isinstance(duel.get('title'),str) or not duel.get('title').strip():issues.append(f'{where_lesson} duel: missing title')
            unsupported=set(duel)-{'id','title'}
            if unsupported:issues.append(f'{where_lesson} duel: unsupported fields: {", ".join(sorted(unsupported))}')
        rounds=t.get('rounds',[])
        if not isinstance(rounds,list):issues.append(f'{where_lesson}: rounds must be a list');continue
        for ri,r in enumerate(rounds,1):
            if not isinstance(r,dict):issues.append(f'{where_lesson} round {ri}: must be an object');continue
            round_where=f'{where_lesson} round {ri}'
            add_id(r.get('id'),round_where)
            if r.get('publicationState') not in PUBLICATION_STATES:issues.append(f'{round_where}: publicationState must be draft or published')
            if r.get('visualType') not in ROUND_VISUAL_TYPES:issues.append(f'{round_where}: visualType must be one of {", ".join(sorted(ROUND_VISUAL_TYPES))}')
            content=r.get('content')
            if not isinstance(content,list):issues.append(f'{round_where}: content must be a list');continue
            if not content:issues.append(f'{round_where}: empty Round')
            if ri==1 and content:
                first=content[0]
                if not isinstance(first,dict) or first.get('role')!='lesson_intro' or first.get('kind')=='exercise':
                    issues.append(f'{round_where}: first Content must be a non-exercise lesson_intro')
            for xi,c in enumerate(content,1):
                where=f'{round_where} content {xi}'
                if not isinstance(c,dict):issues.append(f'{where}: must be an object')
                else:validate_content(c,where)
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
