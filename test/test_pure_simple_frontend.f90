! SPDX-License-Identifier: MIT
program test_pure_simple_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer,parameter::bias=3'//nl//'integer::v'//nl//'v=2'//nl// &
        'call outer(v)'//nl//'print *,v,wrapped(2)'//nl//'contains'//nl// &
        'simple subroutine outer(x)'//nl//'integer,intent(inout)::x'//nl// &
        'call inner(x)'//nl//'end subroutine'//nl// &
        'simple subroutine inner(x)'//nl//'integer,intent(inout)::x'//nl// &
        'x=twice(x)'//nl//'end subroutine'//nl// &
        'integer simple function twice(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=x+x+bias'//nl//'end function'//nl// &
        'pure integer function wrapped(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=twice(x)'//nl//'end function'//nl//'end program'
    character(:),allocatable::changed
    integer::which
    do which=1,14
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        if(.not.all(p%procedures(:4)%is_pure)) error stop 'effective purity missing'
        if(.not.all(p%procedures(:3)%is_simple).or.p%procedures(4)%is_simple) &
            error stop 'SIMPLE distinction missing'
        changed=source
        select case(which)
        case(2);p%procedures(1)%is_pure=.false.
        case(3);p%procedures(2)%is_simple=.false.
        case(4);p%procedures(3)%is_simple=.false.
        case(5);p%procedures(4)%is_simple=.true.
        case(6);changed=replace(source,'simple subroutine outer','pure subroutine outer')
        case(7);changed=replace(source,'integer simple function','integer pure function')
        case(8);changed=replace(source,'pure integer function','simple integer function')
        case(9)
            changed=replace(source,'simple subroutine inner','pure subroutine inner')
            p%procedures(2)%is_simple=.false.;p%procedures(2)%has_pure_prefix=.true.
        case(10)
            changed=replace(source,'integer simple function twice','integer pure function twice')
            p%procedures(3)%is_simple=.false.;p%procedures(3)%has_pure_prefix=.true.
        case(11)
            changed=replace(source,'integer simple function twice','integer function twice')
            p%procedures(3)%is_simple=.false.;p%procedures(3)%is_pure=.false.
        case(12);changed=replace(source,'simple subroutine inner','subroutine inner')
        case(13);changed=replace(source,'pure integer function','integer function')
        case(14)
            changed=replace(source,'simple subroutine outer','subroutine outer')
            p%procedures(1)%is_pure=.false.
        end select
        call verify_frontend(changed,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'PURE/SIMPLE source/IR disagreement admitted'
        end if
    end do
    call rejected(replace(source,'simple subroutine outer','simple simple subroutine outer'),'Duplicate SIMPLE')
    call rejected(replace(source,'pure integer function','pure pure integer function'),'Duplicate PURE')
    call accepted(replace(source,'simple subroutine outer','pure simple subroutine outer'))
    call accepted(replace(source,'integer simple function','simple integer pure function'))
    call rejected(replace(source,'simple subroutine inner','pure subroutine inner'),'not designated SIMPLE')
    call rejected(replace(source,'integer simple function','integer pure function'),'not designated SIMPLE')
    print '(a)','PASS: PURE/SIMPLE baseline, 13 adapter disagreements, 4 parser rejections and 2 redundant-prefix cases'
contains
    function replace(text,old,new) result(out)
        character(*),intent(in)::text,old,new
        character(:),allocatable::out
        integer::i
        i=index(text,old)
        if(i==0) error stop 'test replacement absent'
        out=text(:i-1)//new//text(i+len(old):)
    end function
    subroutine accepted(text)
        character(*),intent(in)::text
        call parse_subset(text,p,d)
        call require_ok('combined prefix parse')
        call verify_frontend(text,p,d)
        call require_ok('combined prefix verification')
    end subroutine
    subroutine rejected(text,wanted)
        character(*),intent(in)::text,wanted
        call parse_subset(text,p,d)
        if(d%code==0) error stop 'invalid PURE/SIMPLE source admitted'
        if(index(d%message,wanted)==0) then
            print *,wanted,d%message
            error stop 'wrong PURE/SIMPLE diagnostic'
        end if
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'PURE/SIMPLE frontend test failed'
    end subroutine
end program
