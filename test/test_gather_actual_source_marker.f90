program test_gather_actual_source_marker
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
character(*),parameter::nl=new_line('a')
character(:),allocatable::head,body,source
integer::variant,e,root,checks
logical::wanted
checks=0
head='module m'//nl//'contains'//nl//'subroutine consume(v)'//nl// &
 'character(*),intent(in)::v(:)'//nl// &
 'if(any(v/=["ef","ab","ef"]))error stop "value"'//nl//'end subroutine'//nl// &
 'subroutine second(s,v)'//nl//'character(*),intent(in)::s'//nl// &
 'character(*),intent(in)::v(:)'//nl//'call consume(v)'//nl//'end subroutine'//nl// &
 'subroutine two(a,v)'//nl//'character(*),intent(in)::a(:),v(:)'//nl// &
 'call consume(v)'//nl//'end subroutine'//nl// &
 'function first(v) result(answer)'//nl//'character(*),intent(in)::v(:)'//nl// &
 'character(2)::answer'//nl//'answer=v(1)'//nl//'end function'//nl// &
 'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'character(2)::x(3)=["ab","cd","ef"]'//nl
do variant=0,9
 wanted=.true.
 select case(variant)
 case(0);body='call consume(x([3,1,3]))';wanted=.false.
 case(1);body='call consume((x([3,1,3])))'
 case(2);body='call consume(v=(x([3,1,3])))'
 case(3);body='call consume(((x([3,1,3]))))'
 case(4);body='call consume( &'//nl//'! grouping after keyword'//nl// &
                'v = & '//nl//' (x([3,1,3])))'
 case(5);body='call consume( &'//nl//' v = & '//nl//' x([3,1,3]))';wanted=.false.
 case(6);body='if(first(x([3,1,3]))/="ef")error stop "function"';wanted=.false.
 case(7);body='if(first((x([3,1,3])))/="ef")error stop "function"'
 case(8);body='call second(",([)]",v=(x([3,1,3])))'
 case(9);body='call two([character(2)::"(",")"],(x([3,1,3])))'
 end select
 source=head//body//nl//'end program'
 call parse_subset(source,p,d)
 call expect(d%code==0,'parse source marker case')
 root=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 call expect(root>0,'gather occurrence')
 call expect(p%expressions(root)%parenthesized.eqv.wanted,'guard source marker')
 call verify_frontend(source,p,d)
 call expect(d%code==0,'independent exact marker acceptance')
 p%expressions(root)%parenthesized=.not.wanted
 call verify_frontend(source,p,d)
 call expect(d%code/=0,'independent opposite marker rejection')
 ! Runtime has IR rather than source: both read-only value contracts are valid
 ! with these distinct bases. Source/IR provenance is the adapter's obligation.
 d=diagnostic_t();call execute_program(p,d)
 call expect(d%code==0,'runtime standalone distinct-base value')
end do
print *,'PASS: gathered actual source marker assertions:',checks
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
if(.not.ok)then
 print *,'FAIL variant',variant,': ',label
 if(allocated(d%message))print *,d%message
 error stop 1
end if
checks=checks+1
end subroutine
end program
