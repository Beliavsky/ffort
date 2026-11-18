! SPDX-License-Identifier: MIT
program test_keyword_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(2,2),b(2,2),v(2),x,y'//nl//'logical :: m(2,2)'//nl// &
        'a=1'//nl//'b=2'//nl//'v=3'//nl//'m=.true.'//nl//'x=4'//nl//'y=5'//nl// &
        'print *,sum(mask=m,dim=1,array=a),product(array=a)'//nl// &
        'print *,lbound(dim=1,array=a),size(array=a)'//nl// &
        'print *,dot_product(vector_b=v,vector_a=v+1)'//nl// &
        'print *,matmul(matrix_b=b,matrix_a=a)'//nl// &
        'print *,subtract(right=5,left=2)'//nl// &
        'call change(second=y,first=x)'//nl//'print *,x,y'//nl//'contains'//nl// &
        'integer function subtract(left,right) result(r)'//nl// &
        'integer,intent(in)::left,right'//nl//'r=left-right'//nl//'end function'//nl// &
        'subroutine change(first,second)'//nl//'integer,intent(inout)::first,second'//nl// &
        'first=first+2'//nl//'second=second+3'//nl//'end subroutine'//nl//'end program'
    character(:),allocatable::changed
    integer::which,e,j,k
    do which=1,29
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        changed=source
        select case(which)
        case(2)
            e=intrinsic('sum');p%expressions(e)%args=p%expressions(e)%args([1,3,2])
        case(3)
            e=intrinsic('matmul');p%expressions(e)%args=p%expressions(e)%args([2,1])
        case(4)
            e=intrinsic('dot_product');p%expressions(e)%args=p%expressions(e)%args([2,1])
        case(5)
            do e=1,p%ne
                if(p%expressions(e)%kind==ex_user_call) exit
            end do
            p%expressions(e)%args=p%expressions(e)%args([2,1])
        case(6)
            do j=1,p%nc
                if(p%code(j)%op==op_call) exit
            end do
            p%code(j)%items=p%code(j)%items([2,1])
        case(7);changed=replace(source,'mask=m','wrong=m')
        case(8);changed=replace(source,'dim=1,array=a','mask=m,array=a')
        case(9);changed=replace(source,'sum(mask=m,dim=1,array=a)','sum(mask=m,1,a)')
        case(10);changed=replace(source,'product(array=a)','product(mask=m)')
        case(11);changed=replace(source,'vector_b=v','vector_a=v')
        case(12);changed=replace(source,'matrix_b=b','matrix_a=b')
        case(13);changed=replace(source,'right=5,left=2','left=5,right=2')
        case(14);changed=replace(source,'right=5,left=2','right=5,right=2')
        case(15);changed=replace(source,'right=5,left=2','5,left=2')
        case(16);changed=replace(source,'right=5,left=2','right=5,2')
        case(17);changed=replace(source,'second=y,first=x','first=y,second=x')
        case(18);changed=replace(source,'second=y,first=x','first=y,first=x')
        case(19);changed=replace(source,'second=y,first=x','second=y,unknown=x')
        case(20);changed=replace(source,'lbound(dim=1,array=a)','lbound(dim=1)')
        case(21);changed=replace(source,'size(array=a)','size(array=a,kind=4)')
        case(22);changed=replace(source,'mask=m,dim=1,array=a','mask=m,dim=.true.,array=a')
        case(23);changed=replace(source,'mask=m,dim=1,array=a','mask=1,dim=1,array=a')
        case(24)
            e=intrinsic('sum');p%expressions(e)%args(1)=0
        case(25)
            e=intrinsic('sum');p%expressions(e)%args=p%expressions(e)%args(:2)
        case(26)
            e=intrinsic('sum');p%expressions(e)%rank=0
        case(27)
            do j=1,p%np
                if(p%procedures(j)%name=='subtract') exit
            end do
            k=p%procedures(j)%args(1);p%symbols(k)%name='renamed'
        case(28);changed=replace(source,'product(array=a)','product(dim=a)')
        case(29);changed=replace(source,'size(array=a)','size(dim=a)')
        end select
        call verify_frontend(changed,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'keyword source/IR disagreement admitted'
        end if
    end do
    print '(a)','PASS: keyword baseline and 28 adapter disagreements'
contains
    integer function intrinsic(name) result(e)
        character(*),intent(in)::name
        do e=1,p%ne
            if(p%expressions(e)%kind==ex_call.and.p%expressions(e)%op==name) return
        end do
        error stop 'test call absent'
    end function
    function replace(text,old,new) result(out)
        character(*),intent(in)::text,old,new
        character(:),allocatable::out
        integer::i
        i=index(text,old)
        if(i==0) error stop 'test replacement absent'
        out=text(:i-1)//new//text(i+len(old):)
    end function
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'keyword frontend test failed'
    end subroutine
end program
