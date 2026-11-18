! SPDX-License-Identifier: MIT
program test_array_bounds_constructor_owner
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,name,body
    integer::family,form,mutation,e,a,j,checks,which,owners(3)
    checks=0;owners=[-1,1,max_expressions+1]
    do family=1,2
      name='lbound';if(family==2)name='ubound'
      do form=1,3
        body='b='//name//'(x,kind=8)'
        if(form==2)body='b=kind('//name//'(x,kind=8))'
        if(form==3)body='empty=empty+sum('//name//'(x,kind=8))'
        source='program p'//nl//'real::x(2,3)'//nl//'integer(8)::b(2),empty(0)'//nl//body//nl//'end program'
        do which=1,2
          do mutation=0,3
            call parse_subset(source,p,d);call expect(d%code==0,'owner control parse')
            do j=1,p%ne
              if(p%expressions(j)%op==name)e=j
            end do
            a=e;if(which==2)a=p%expressions(e)%args(1)
            if(mutation/=0)p%expressions(a)%constructor_owner=owners(mutation)
            call expect(valid_bounds_inquiry(p,e).eqv.(mutation==0),'strict public predicate')
            call verify_frontend(source,p,d)
            call expect(d%code==merge(0,1,mutation==0),'source adapter owner guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect(d%code==merge(0,2,mutation==0),'runtime owner guard')
          end do
        end do
      end do
      source='program p'//nl//'integer::x(2,3),i,b(2)'//nl// &
             'b=[('//name//'(x,i),i=1,2)]'//nl//'end program'
      call parse_subset(source,p,d);call expect(d%code==0,'legal constructor DIM parse')
      do j=1,p%ne
        if(p%expressions(j)%op==name)e=j
      end do
      call expect(valid_bounds_inquiry(p,e),'legal constructor-index DIM accepted')
      call verify_frontend(source,p,d);call expect(d%code==0,'legal constructor DIM adapter')
      call execute_program(p,d);call expect(d%code==0,'legal constructor DIM runtime')
    end do
    print *,'PASS: bounds constructor-owner assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,name,form,which,mutation,label
      if(allocated(d%message))print *,d%message
      error stop 'bounds constructor-owner guard failure'
    end subroutine
end program
