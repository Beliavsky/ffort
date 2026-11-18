program test_read_sections_independent
use,intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::source='program p'//nl//'implicit none'//nl// &
 'character(40) :: text'//nl//'integer :: a(-2:3),lo,hi,step,ios'//nl// &
 'text="11 22 33"'//nl//'a=-1'//nl//'lo=-2'//nl//'hi=2'//nl//'step=2'//nl// &
 'read(text,*,iostat=ios) a(lo:hi:step)'//nl// &
 'if(ios/=0.or.any(a/=[11,-1,22,-1,33,-1])) stop 1'//nl//'end program'
type(program_t)::p,q
type(diagnostic_t)::d
integer::checks=0,pc,root,s,j,k,n,leaf
call parse_subset(source,p,d);call check(d%code==0,'baseline parser')
call verify_frontend(source,p,d);call check(d%code==0,'baseline strict frontend')
pc=0
 do j=1,p%nc
 if(p%code(j)%op==op_read_internal)pc=j
 end do
call check(pc>0,'read located');root=p%code(pc)%items(1);s=p%expressions(root)%symbol
call check(p%expressions(root)%kind==ex_section,'section target')
call check(valid_internal_read(p,p%code(pc)),'baseline admission')
call execute_program(p,d);call check(d%code==0,'baseline runtime exact selected writes')
do k=1,32
 q=p
 select case(k)
 case(1);q%expressions(root)%symbol=0
 case(2);q%expressions(root)%symbol=p%ns+1
 case(3);q%expressions(root)%rank=0
 case(4);q%expressions(root)%rank=2
 case(5);q%expressions(root)%typ=ty_real
 case(6);q%expressions(root)%real_kind=8
 case(7);q%expressions(root)%character_len=4
 case(8);q%expressions(root)%dims(1)=2
 case(9);q%expressions(root)%parenthesized=.true.
 case(10);q%expressions(root)%left=-1
 case(11);q%expressions(root)%left=p%ne+1
 case(12);q%expressions(root)%right=-1
 case(13);q%expressions(root)%stride=p%ne+1
 case(14);q%expressions(root)%left=root
 case(15);q%expressions(root)%right=root
 case(16);q%expressions(root)%stride=root
 case(17);q%expressions(root)%left2=1
 case(18);q%expressions(root)%right2=1
 case(19);q%expressions(root)%stride2=1
 case(20);q%expressions(root)%left3=1
 case(21);q%expressions(root)%right3=1
 case(22);q%expressions(root)%stride3=1
 case(23);q%expressions(root)%third=1
 case(24);q%expressions(root)%length_expr=1
 case(25);q%expressions(root)%constructor_owner=1
 case(26);q%expressions(root)%generic_id=1
 case(27);q%expressions(root)%bound_type=1
 case(28);q%expressions(root)%intrinsic_mask=1
 case(29);q%expressions(root)%op='forged'
 case(30);q%expressions(root)%args=[1]
 case(31);q%expressions(root)%triplet(1)=.false.
 case(32);q%expressions(root)%value%tag=ty_integer
 end select
 call check(.not.valid_internal_read(q,q%code(pc)),'mutated section gate')
 d=diagnostic_t();call execute_program(q,d);call check(d%code/=0,'mutated section runtime reject')
 d=diagnostic_t();call verify_frontend(source,q,d);call check(d%code/=0,'mutated section frontend reject')
end do
! Index roots must not cycle or masquerade as a different declared type/kind.
leaf=p%expressions(root)%left
q=p;q%expressions(leaf)%kind=ex_unary;q%expressions(leaf)%left=leaf;q%expressions(leaf)%symbol=0
q%expressions(leaf)%op='+';call check(.not.valid_internal_read(q,q%code(pc)),'bound cycle')
q=p;q%expressions(leaf)%real_kind=8;call check(.not.valid_internal_read(q,q%code(pc)),'bound kind forgery')
q=p;q%expressions(leaf)%rank=1;call check(.not.valid_internal_read(q,q%code(pc)),'bound rank forgery')
q=p;q%expressions(leaf)%extent=1;call check(.not.valid_internal_read(q,q%code(pc)),'bound hidden extent')
q=p;q%expressions(leaf)%symbol=p%expressions(p%code(pc)%b)%symbol
call check(.not.valid_internal_read(q,q%code(pc)),'IOSTAT-dependent bounds')
q=p;q%symbols(s)%is_dummy=.true.;q%symbols(s)%dummy_intent=1;call check(.not.valid_internal_read(q,q%code(pc)),'readonly target')
q=p;q%code(pc)%items=[root,root];call check(.not.valid_internal_read(q,q%code(pc)),'duplicate target alias')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="1 2 3"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(5:1:-2)'//nl// &
 'if(ios/=0.or.any(a/=[3,-1,2,-1,1]))stop 1','negative stride order')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="bad"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(3:1)'//nl// &
 'if(ios/=0.or.any(a/=-1))stop 1','empty section consumes no input')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="1,,3"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:5:2)'//nl// &
 'if(ios/=0.or.any(a/=[1,-1,-1,-1,3]))stop 1','null leaves selected element unchanged')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="1 /"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:5:2)'//nl// &
 'if(ios/=0.or.any(a/=[1,-1,-1,-1,-1]))stop 1','slash stops selected sequence')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="1 bad 3"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:5:2)'//nl// &
 'if(ios<=0.or.a(2)/=-1.or.a(4)/=-1)stop 1','conversion failure preserves unselected values')
call run('character(30)::text'//nl//'integer::a(5),ios'//nl// &
 'text="1"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:5:2)'//nl// &
 'if(ios>=0.or.a(2)/=-1.or.a(4)/=-1)stop 1','EOF preserves unselected values')
call run('character(30)::text'//nl//'integer::a(4),ios,i'//nl// &
 'text="7 8"'//nl//'a=-1'//nl//'do i=1,2'//nl//'read(text,*,iostat=ios)a(i:i+2:2)'//nl// &
 'end do'//nl//'if(ios/=0.or.any(a/=[7,7,8,8]))stop 1','fresh destination reevaluation per READ')
call fails('character(30)::text'//nl//'integer::a(3),ios,n'//nl// &
 'text="1 bad"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:3:2)'//nl// &
 'n=a(1)','conversion failure undefines selected prefix')
call fails('character(30)::text'//nl//'integer::a(3),ios,n'//nl// &
 'text="1"'//nl//'a=-1'//nl//'read(text,*,iostat=ios)a(1:3:2)'//nl// &
 'n=a(3)','EOF undefines selected suffix')
call run('character(40)::text'//nl//'character(4),allocatable::a(:)'//nl//'integer::ios'//nl// &
 'allocate(a(-1:3))'//nl//'a="hold"'//nl//"text="//achar(34)//"'ab',,'cd'"//achar(34)//nl// &
 'read(text,*,iostat=ios)a(-1:3:2)'//nl// &
 'if(ios/=0.or.a(-1)/="ab".or.a(1)/="hold".or.a(3)/="cd".or.a(0)/="hold")stop 1', &
 'allocated CHARACTER section null preserves values')
call run('character(40)::text'//nl//'character(4)::a(3)'//nl//'integer::ios'//nl// &
 'a="hold"'//nl//"text="//achar(34)//"'ab' /"//achar(34)//nl//'read(text,*,iostat=ios)a(1:3:2)'//nl// &
 'if(ios/=0.or.a(1)/="ab".or.a(2)/="hold".or.a(3)/="hold")stop 1','CHARACTER slash')
call run('character(40)::text'//nl//'character(4),allocatable::a(:)'//nl//'integer::ios'//nl// &
 'allocate(a(3))'//nl//'a="hold"'//nl//"text="//achar(34)//"'ab'"//achar(34)//nl//'read(text,*,iostat=ios)a(1:3:2)'//nl// &
 'if(ios>=0.or.a(2)/="hold")stop 1','allocated CHARACTER EOF unselected preserved')
d=diagnostic_t();call parse_subset('program p'//nl//'character(40)::text'//nl//'character(4)::a(3)'//nl// &
 'text="abc def"'//nl//'read(text,*)a(1:3:2)'//nl//'end program'//nl,q,d)
call check(d%code==0,'CHARACTER mutation parser')
do j=1,q%nc
 if(q%code(j)%op==op_read_internal)pc=j
end do
root=q%code(pc)%items(1)
call check(valid_internal_read(q,q%code(pc)),'CHARACTER canonical gate')
q%expressions(root)%character_len=q%expressions(root)%character_len+1
call check(.not.valid_internal_read(q,q%code(pc)),'CHARACTER section length forgery')
print *, 'independent READ section checks:',checks
contains
subroutine run(body,label)
character(*),intent(in)::body,label
type(program_t)::r
d=diagnostic_t();call parse_subset('program p'//nl//body//nl//'end program'//nl,r,d)
call check(d%code==0,'behavior parser '//label)
call verify_frontend('program p'//nl//body//nl//'end program'//nl,r,d)
call check(d%code==0,'behavior frontend '//label)
call execute_program(r,d);call check(d%code==0,label)
end subroutine
subroutine fails(body,label)
character(*),intent(in)::body,label
type(program_t)::r
d=diagnostic_t();call parse_subset('program p'//nl//body//nl//'end program'//nl,r,d)
call check(d%code==0,'failure behavior parser '//label)
call execute_program(r,d);call check(d%code/=0,label)
end subroutine
subroutine check(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
if(.not.ok)then
 print *,'FAILED ',label
 if(allocated(d%message))print *,d%message
 stop 1
end if
checks=checks+1
end subroutine
end program
