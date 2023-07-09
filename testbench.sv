class transactiona;
  rand bit[31:0] m;
  
   constraint denorm{m[30:23]!='0;}
   constraint infinity{m[30:23]!='1 && m[22:0]!='0; }
   constraint NAN{m[30:23]!='1;}
   constraint sign{m[31]==1'b0;}
  
endclass

class transactionb;
  rand bit[31:0] n;

  constraint denorm{n[30:23]!='0;}
  constraint infinity{n[30:23]!='1 && n[22:0]!='0; }
  constraint NAN{n[30:23]!='1;}
  constraint sign{n[31]==1'b0;}
endclass

class coverage_module;
  bit [31:0]a;
  bit [31:0]b;
  bit [31:0]fp_result;
  
  covergroup fp_type;
	option.per_instance = 1; 
	coverpoint fp_result{
       bins b1={[32'b0_0000_0000_0000_0000_0000_0000_0000_000:32'b0_0000_0000_0000_0000_0000_1111_1111_110]};
       bins zero={32'b0};
	 }  
  endgroup
  
  function new();
    fp_type = new;
  endfunction
endclass     

import float_type::*;

module top;
  logic [31:0]a,b;
  bit [31:0] fp_result,rp;
  bit U,O,N,U_test,O_test;
  shortreal r_a,r_b,r_product;
  int failed;
  real r_product_real;
  bit[47:0]result;
  
  type_of_float result_str;

  transactiona tra;
  transactionb trb;
  coverage_module cg;

  product p(.a(a), .b(b), .fp_result(fp_result), .U(U), .O(O),.N(N));
  binary_24bitmultiplier mul(.a(p.a_new),.b(p.b_new),.result(result));
  `ifdef DIRECTED_CASES
  initial
  $display("entered directed cases");
   task display();
     r_a=$bitstoshortreal(a) ;
     r_b=$bitstoshortreal(b) ;
    r_product_real = r_a*r_b;
     r_product=r_a*r_b;
     

    if(a[31]^b[31]==0)
    begin 
		if(a[30:0] =='0 || b[30:0] =='0) 
		begin
			O_test=0;U_test=0;
		end       
    else if (r_product_real > 3.40282347e38) 
	begin
        O_test=1;U_test=0;
	end
    else if (r_product_real < 1.17549435e-38) 
	begin
        U_test=1;O_test=0; 
	end
    else 
	begin
		O_test=0;  U_test=0; 
	end
	end
     
    else 
	begin
		if(a[30:0]=='0 || b[30:0]=='0) 
		begin
			O_test=0;U_test=0;
        end
        else if (r_product_real > -1.17549435e-38) 
		begin
			U_test=1;O_test=0;
		end
		else if (r_product_real < -3.40282347e38) 
		begin
			O_test=1;U_test=0; 
		end
		else 
		begin
			O_test=0;  U_test=0; 
		end 
     end
         
         if((p.float_a == positive_infinity) || (p.float_a ==negative_infinity) ||(p.float_a == NaN)||(p.float_b == positive_infinity) || (p.float_b ==negative_infinity) ||(p.float_b == NaN)) 
		 begin
			$display("One of the input is %s",p.result_str);
			$display("@%0t a=%b b=%b",$time,a,b);
			$display("__");
         end
         
         else if(N==1) 
		 begin
			$display("Multiplication result is not a number!");
			$display("@%0t a=%b b=%b fp_result=%b",$time,a,b,fp_result);
            $display("r_a=%g r_b=%g r_product=%g O=%b U=%b",r_a,r_b,r_product,O_test,U_test);
			$display("__");
         end
         
         else if ((O==1)||(U==1)||(p.result_str==ZERO))
         begin 
			$display(" Float Multiplication: %s", p.result_str); 
			$display("@%0t a=%b b=%b fp_result=%b Overflow=%0b Underflow=%0b",$time,a,b,fp_result,O,U);
			$display("r_a=%g r_b=%g r_product=%g O=%b U=%b",r_a,r_b,r_product,O_test,U_test);
			$display("__");
         end
         
		else if((((O==O_test)&&(U==U_test)) || ($shortrealtobits(r_product)==fp_result))) begin
			$display("@%0t a=%b b=%b fp_result=%b Overflow=%0b Underflow=%0b Result is: %s",$time,a,b,fp_result,O,U,p.result_str);
			$display("r_a=%g r_b=%g r_product=%g O=%b U=%b",r_a,r_b,r_product,O_test,U_test);
			$display("__");
		end
	endtask
 
  initial 
  begin
   
     //b-negative infinity
    a = 32'b1_11111110_11111111111111111111111; 
    b = 32'b1_11111111_00000000000000000000000;#10;
     display();
    
    //a-positive infinity
     a = 32'b0_11111111_00000000000000000000000;
     b = 32'b1_11111110_11111111111110011111111;#10;
     display();
    
    //a- NaN
    a = 32'b1_11111111_00110011001100110011010; 
    b = 32'b0_01111111_11110100010000000000000;#10;
    display();
    
    //unknown inputs
      a = 32'b1_11111110_11110100010000000000000; 
     b = 'x;#10;
      display();
    
   //positive normalized x positive normalized 
    a = 32'b0_10000001_00000000000000000000000;
    b = 32'b0_10000000_00110011001100110011000;#10;
    display();
    
  //negative normalized x negative normalized
    a = 32'b1_10000001_00000000000000000000000;
    b = 32'b1_10000000_10000000000000000000000; #10;
    display();
    
     //negative normalized x positive normalized
    a = 32'b1_01111101_00000000000000000000000; 
    b = 32'b0_10000111_00000000000000000000000;#10;
      display();
    
  //underflow 
    a = 32'b0_00000000_01000000000000000000000;
    b = 32'b0_00000000_01000000000000000000000;#10;
    display();
    
    //overflow
	 a = 32'b1_11111110_11111111111111111111111; 
    b = 32'b1_11111110_00000000000000000000000;#10;
     display();
     
    //zeroes
     a = 32'b0_00000000_00000000000000000000000; 
    b = 32'b0_00000000_00000000000000000000000;#10;
     display();
    
    //normalized x zero
    a = 32'b1_10001110_11111111100000111111111;  
     b = 32'b0_00000000_00000000000000000000000;#10;
     display();
    
    //normalized x 1
     a = 32'b1_10001110_11111111100000110011111;  
     b = 32'b0_01111111_00000000000000000000000;#10;
     display();
    
    //normalized x 1
     a = 32'b0_10001110_11111111100000110011111;  
     b = 32'b1_01111111_00000000000000000000000;#10;
     display();
    // number x its reciprocal
    a= 32'b0_10000000_00000000000000000000000;
    b= 32'b0_01111110_00000000000000000000000; #10;
    display();
  end
  
`else
  initial 
  begin 
      tra = new();
      trb = new();
      cg = new();
    repeat(1000) 
	begin
      while((cg.fp_type.get_coverage() < 100)) 
	  begin
        assert(tra.randomize());
        assert(trb.randomize());
        cg.fp_type.sample();
        a = tra.m;
        b = trb.n;
        #10;
		a=32'b0;b=32'b0;#10;
		a=32'b0_0000_0000_0000_0000_0100_1111_1111_111;b=32'b0_0111_1111_0000_0000_0000_0000_0000_000;
		#10;
		a=32'b0_0000_1000_0000_0000_0100_1111_1111_111;b=32'b0_0111_1111_0000_0000_0000_0000_0000_000;
		#10;
        r_a = $bitstoshortreal(a);
        r_b = $bitstoshortreal(b);
        r_product = r_a * r_b;
        rp=$shortrealtobits(r_product);
        r_product_real = r_a*r_b;
     
      if(a[31]^b[31]==0)
        begin  
		if (r_product_real > 3.40282347e38) 
		begin
			O_test=1;U_test=0;
		end
		else if (r_product_real < 1.17549435e-38) 
		begin
			U_test=1;O_test=0; 
		end
		else 
		begin
			O_test=0;  U_test=0;
		end
      end
     
     else 
	 begin
        if (r_product_real > -1.17549435e-38) 
		begin
			U_test=1;O_test=0;
		end
		else if (r_product_real < -3.40282347e38) 
		begin
			O_test=1;U_test=0; 
		end
		else 
		begin
			O_test=0; U_test=0; 
		end
     end
        
        if (N!=1) 
		begin
          if (rp!=(fp_result)) 
		  begin
			if ((U!=U_test) || (O!=O_test)) 
			begin
				$display("@%t a=%b b=%b fp_result=%b O=%b U=%b rcary=%b addexp=%b carry=%b result_mantissa=%b result=%b a_new=%b b_new=%b mul_result=%b multiplier_result=%b count=%0d",$time, a, b, fp_result,O,U,p.round_carry,p.additional_exponent,p.carry,p.result_mantissa,result,p.a_new,p.b_new,p.mul_result,p.multiplier_result,p.count);
				$display("@%t a=%g b=%g fp_result=%b r_product=%g O_test=%b U_test=%b",$time, r_a, r_b, rp,r_product,O_test,U_test);
				$display("-----------------------------------"); 
				failed=failed+1;
            end
		  end
		end 
	end
    end
    $display("overall coverage = %0f", $get_coverage());
    if (failed==0)
    $display("-------Passed!----------"); 
    end
  `endif
endmodule